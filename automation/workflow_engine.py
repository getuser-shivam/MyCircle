#!/usr/bin/env python3
"""
Workflow Engine for Auto-Prompt GUI
Sequences prompts one-after-another with pause/resume/cancel controls.
"""

import json
import time
import threading
import copy
import os
from pathlib import Path
from typing import Dict, List, Optional, Callable, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class WorkflowStep:
    """A single step in a workflow"""

    def __init__(self, name: str, prompt: str, delay_after: float = 3.0,
                 condition: str = "", enabled: bool = True):
        self.name = name
        self.prompt = prompt
        self.delay_after = delay_after  # seconds to wait after this step
        self.condition = condition  # optional condition string
        self.enabled = enabled
        self.status = "pending"  # pending | running | completed | failed | skipped
        self.result = ""
        self.started_at: Optional[datetime] = None
        self.completed_at: Optional[datetime] = None

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "prompt": self.prompt,
            "delay_after": self.delay_after,
            "condition": self.condition,
            "enabled": self.enabled,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "WorkflowStep":
        return cls(
            name=data.get("name", "Untitled Step"),
            prompt=data.get("prompt", ""),
            delay_after=data.get("delay_after", 3.0),
            condition=data.get("condition", ""),
            enabled=data.get("enabled", True),
        )


class Workflow:
    """A complete workflow with ordered steps"""

    def __init__(self, name: str, description: str = "", steps: List[WorkflowStep] = None):
        self.name = name
        self.description = description
        self.steps: List[WorkflowStep] = steps or []
        self.variables: Dict[str, str] = {}
        self.created_at = datetime.now().isoformat()

    def add_step(self, step: WorkflowStep):
        self.steps.append(step)

    def remove_step(self, index: int):
        if 0 <= index < len(self.steps):
            self.steps.pop(index)

    def move_step(self, from_idx: int, to_idx: int):
        if 0 <= from_idx < len(self.steps) and 0 <= to_idx < len(self.steps):
            step = self.steps.pop(from_idx)
            self.steps.insert(to_idx, step)

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "description": self.description,
            "steps": [s.to_dict() for s in self.steps],
            "variables": self.variables,
            "created_at": self.created_at,
        }

    @classmethod
    def from_dict(cls, data: dict) -> "Workflow":
        wf = cls(
            name=data.get("name", "Untitled"),
            description=data.get("description", ""),
        )
        wf.variables = data.get("variables", {})
        wf.created_at = data.get("created_at", datetime.now().isoformat())
        for step_data in data.get("steps", []):
            wf.add_step(WorkflowStep.from_dict(step_data))
        return wf

    def resolve_prompt(self, step: WorkflowStep) -> str:
        """Replace template variables in prompt text"""
        prompt = step.prompt
        for key, value in self.variables.items():
            prompt = prompt.replace(f"{{{key}}}", value)
        return prompt


class WorkflowEngine:
    """Engine that executes workflows step by step"""

    def __init__(self):
        self._current_workflow: Optional[Workflow] = None
        self._current_step_index: int = -1
        self._running = False
        self._paused = False
        self._cancel_requested = False
        self._lock = threading.Lock()
        self._pause_event = threading.Event()
        self._pause_event.set()  # not paused initially
        self._thread: Optional[threading.Thread] = None

        # Looping state
        self.loop_mode = False
        self.loop_interval = 120.0  # default 2 mins
        self._loop_countdown = 0.0

        # Callbacks
        self.on_step_start: Optional[Callable[[int, WorkflowStep], None]] = None
        self.on_step_complete: Optional[Callable[[int, WorkflowStep, str], None]] = None
        self.on_workflow_done: Optional[Callable[[Workflow, str], None]] = None
        self.on_error: Optional[Callable[[int, WorkflowStep, str], None]] = None
        self.on_progress: Optional[Callable[[int, int, float], None]] = None

        # The send_prompt function — set by the GUI to bridge to the editor
        self.send_prompt_fn: Optional[Callable[[str], str]] = None

        # Auto-interact mode: send AND wait for AI completion
        self.send_and_wait_fn: Optional[Callable[[str], str]] = None

        self.on_loop_wait: Optional[Callable[[float], None]] = None

        # Built-in workflows
        self.builtin_workflows = self._create_builtin_workflows()

    @property
    def is_running(self) -> bool:
        return self._running

    @property
    def is_paused(self) -> bool:
        return self._paused

    @property
    def current_step_index(self) -> int:
        return self._current_step_index

    def start(self, workflow: Workflow):
        """Start executing a workflow in a background thread"""
        if self._running:
            raise RuntimeError("A workflow is already running")

        self._current_workflow = workflow
        self._current_step_index = -1
        self._running = True
        self._paused = False
        self._cancel_requested = False
        self._pause_event.set()

        # Reset all step statuses
        for step in workflow.steps:
            step.status = "pending"
            step.result = ""
            step.started_at = None
            step.completed_at = None

        self._thread = threading.Thread(target=self._run_workflow, daemon=True)
        self._thread.start()

    def pause(self):
        """Pause the current workflow"""
        with self._lock:
            if self._running and not self._paused:
                self._paused = True
                self._pause_event.clear()

    def resume(self):
        """Resume a paused workflow"""
        with self._lock:
            if self._running and self._paused:
                self._paused = False
                self._pause_event.set()

    def cancel(self):
        """Cancel the current workflow"""
        with self._lock:
            self._cancel_requested = True
            self.loop_mode = False  # disable loop on cancel
            self._paused = False
            self._pause_event.set()  # unblock if paused

    def _run_workflow(self):
        """Main workflow execution loop (runs in background thread)"""
        workflow = self._current_workflow
        
        while True:
            total_steps = len(workflow.steps)
            
            try:
                for i, step in enumerate(workflow.steps):
                    # Check cancel
                    if self._cancel_requested:
                        step.status = "skipped"
                        continue

                    # Wait if paused
                    self._pause_event.wait()

                    if self._cancel_requested:
                        step.status = "skipped"
                        continue

                    # Skip disabled steps
                    if not step.enabled:
                        step.status = "skipped"
                        continue

                    # Start step
                    self._current_step_index = i
                    step.status = "running"
                    step.started_at = datetime.now()

                    if self.on_step_start:
                        try:
                            self.on_step_start(i, step)
                        except Exception:
                            pass

                    # Progress callback
                    if self.on_progress:
                        progress = ((i) / total_steps) * 100
                        try:
                            self.on_progress(i, total_steps, progress)
                        except Exception:
                            pass

                    # Execute the prompt
                    resolved_prompt = workflow.resolve_prompt(step)

                    try:
                        if self.send_and_wait_fn:
                            # Auto-interact: send prompt AND wait for AI to finish
                            result = self.send_and_wait_fn(resolved_prompt)
                        elif self.send_prompt_fn:
                            result = self.send_prompt_fn(resolved_prompt)
                        else:
                            result = f"[Dry Run] Prompt queued: {resolved_prompt[:80]}..."

                        step.status = "completed"
                        step.result = result or "Done"
                        step.completed_at = datetime.now()

                        if self.on_step_complete:
                            try:
                                self.on_step_complete(i, step, result)
                            except Exception:
                                pass

                    except Exception as e:
                        step.status = "failed"
                        step.result = str(e)
                        step.completed_at = datetime.now()

                        if self.on_error:
                            try:
                                self.on_error(i, step, str(e))
                            except Exception:
                                pass

                    # Delay between steps (only as cooldown when NOT using send_and_wait)
                    if not self.send_and_wait_fn:
                        if i < total_steps - 1 and step.delay_after > 0:
                            delay_end = time.time() + step.delay_after
                            while time.time() < delay_end:
                                if self._cancel_requested:
                                    break
                                self._pause_event.wait(timeout=0.2)
                
                # Workflow loop run complete
                if not self.loop_mode or self._cancel_requested:
                    break
                
                # Handle Looping
                if self.on_workflow_done:
                    try:
                        self.on_workflow_done(workflow, "looping")
                    except Exception:
                        pass
                
                # Reset steps for next run
                for step in workflow.steps:
                    step.status = "pending"
                
                # Wait for interval
                self._loop_countdown = self.loop_interval
                while self._loop_countdown > 0:
                    if self._cancel_requested or not self.loop_mode:
                        break
                    
                    if self.on_loop_wait:
                        self.on_loop_wait(self._loop_countdown)
                    
                    sleep_time = min(1.0, self._loop_countdown)
                    time.sleep(sleep_time)
                    self._loop_countdown -= sleep_time
                
                if self._cancel_requested or not self.loop_mode:
                    break

            except Exception as e:
                logger.error(f"Workflow execution error: {e}")
                if self.on_workflow_done:
                    try:
                        self.on_workflow_done(workflow, f"error: {e}")
                    except Exception:
                        pass
                break

        # Final completion
        status = "cancelled" if self._cancel_requested else "completed"
        if self.on_progress:
            try:
                self.on_progress(len(workflow.steps), len(workflow.steps), 100)
            except Exception:
                pass

        if self.on_workflow_done:
            try:
                self.on_workflow_done(workflow, status)
            except Exception:
                pass

        self._running = False
        self._paused = False
        self._current_step_index = -1

    def _create_builtin_workflows(self) -> Dict[str, Workflow]:
        """Create built-in preset workflows"""
        workflows = {}

        # === Full Feature Development ===
        wf = Workflow(
            name="Full Feature Dev",
            description="End-to-end feature development: analyze → model → UI → state → test"
        )
        wf.add_step(WorkflowStep(
            name="1. Analyze Project",
            prompt=(
                "Analyze the project at {project_path}. "
                "Review the folder structure, existing screens, providers, models, and services. "
                "Summarize what the app does and list all existing features."
            ),
            delay_after=5.0,
        ))
        wf.add_step(WorkflowStep(
            name="2. Design Feature",
            prompt=(
                "Based on the project analysis, design the '{feature_name}' feature. "
                "Create a detailed implementation plan including:\n"
                "- Data models needed\n"
                "- API endpoints / Supabase tables\n"
                "- UI screens and widgets\n"
                "- State management (Provider/Riverpod)\n"
                "- Navigation flow\n"
                "Write the plan as a markdown checklist."
            ),
            delay_after=5.0,
        ))
        wf.add_step(WorkflowStep(
            name="3. Create Data Models",
            prompt=(
                "Implement the data models for '{feature_name}' as designed in the plan. "
                "Create Dart model classes in lib/models/ with:\n"
                "- JSON serialization (fromJson / toJson)\n"
                "- copyWith method\n"
                "- Proper type annotations\n"
                "Follow the existing code style in the project."
            ),
            delay_after=5.0,
        ))
        wf.add_step(WorkflowStep(
            name="4. Build UI Screens",
            prompt=(
                "Build the UI screens for '{feature_name}' in lib/screens/. "
                "Create beautiful, responsive Flutter widgets following Material 3 design. "
                "Use the existing theme and design patterns from the project. "
                "Include proper error states, loading indicators, and empty states."
            ),
            delay_after=5.0,
        ))
        wf.add_step(WorkflowStep(
            name="5. Add State Management",
            prompt=(
                "Create the state management for '{feature_name}'. "
                "Add Provider/ChangeNotifier classes in lib/providers/. "
                "Connect the UI screens to the providers. "
                "Handle loading states, error states, and data caching. "
                "Follow the existing provider patterns in the project."
            ),
            delay_after=5.0,
        ))
        wf.add_step(WorkflowStep(
            name="6. Write Tests",
            prompt=(
                "Write comprehensive tests for the '{feature_name}' feature:\n"
                "- Unit tests for models and providers\n"
                "- Widget tests for UI components\n"
                "Put tests in the test/ directory mirroring the lib/ structure. "
                "Aim for good coverage of edge cases."
            ),
            delay_after=3.0,
        ))
        wf.add_step(WorkflowStep(
            name="7. Integration Check",
            prompt=(
                "Review all the code created for '{feature_name}'. "
                "Check for:\n"
                "- Missing imports\n"
                "- Navigation routes registered\n"
                "- Provider registered in main.dart\n"
                "- No compile errors\n"
                "Fix any issues found and confirm the feature is fully integrated."
            ),
            delay_after=2.0,
        ))
        workflows["Full Feature Dev"] = wf

        # === Bug Fix & Test ===
        wf2 = Workflow(
            name="Bug Fix & Test",
            description="Diagnose a bug, fix it, write a regression test, and verify"
        )
        wf2.add_step(WorkflowStep(
            name="1. Diagnose Bug",
            prompt=(
                "There is a bug in the project at {project_path}: '{bug_description}'. "
                "Investigate the issue by:\n"
                "- Reading the relevant source files\n"
                "- Tracing the data flow\n"
                "- Identifying the root cause\n"
                "Explain what's happening and why."
            ),
            delay_after=5.0,
        ))
        wf2.add_step(WorkflowStep(
            name="2. Implement Fix",
            prompt=(
                "Fix the bug identified in the previous step. "
                "Make the minimal necessary changes. "
                "Explain each change you make and why it fixes the issue."
            ),
            delay_after=5.0,
        ))
        wf2.add_step(WorkflowStep(
            name="3. Write Regression Test",
            prompt=(
                "Write a regression test that would catch this bug if it reappears. "
                "The test should:\n"
                "- Reproduce the exact scenario that triggered the bug\n"
                "- Verify the fix works correctly\n"
                "- Cover any related edge cases"
            ),
            delay_after=3.0,
        ))
        wf2.add_step(WorkflowStep(
            name="4. Verify Fix",
            prompt=(
                "Run the tests and verify the bug fix is working. "
                "Also check that no other tests broke. "
                "Summarize the fix, the test results, and any remaining concerns."
            ),
            delay_after=2.0,
        ))
        workflows["Bug Fix & Test"] = wf2

        # === Code Review & Refactor ===
        wf3 = Workflow(
            name="Code Review & Refactor",
            description="Deep code review, identify improvements, refactor, and verify"
        )
        wf3.add_step(WorkflowStep(
            name="1. Deep Code Review",
            prompt=(
                "Perform a thorough code review of {file_path} in the project at {project_path}. "
                "Analyze:\n"
                "- Code quality and readability\n"
                "- Performance issues\n"
                "- Security concerns\n"
                "- Design pattern violations\n"
                "- Missing error handling\n"
                "Rate each issue by severity (Critical/High/Medium/Low)."
            ),
            delay_after=5.0,
        ))
        wf3.add_step(WorkflowStep(
            name="2. Refactor Code",
            prompt=(
                "Refactor the code based on the review findings. "
                "Priority order: Critical → High → Medium. "
                "Apply clean code principles, improve naming, extract methods, "
                "add proper error handling, and optimize performance. "
                "Keep the public API stable."
            ),
            delay_after=5.0,
        ))
        wf3.add_step(WorkflowStep(
            name="3. Add Documentation",
            prompt=(
                "Add comprehensive documentation to the refactored code:\n"
                "- Class-level dartdoc comments\n"
                "- Method documentation with @param and @return\n"
                "- Inline comments for complex logic\n"
                "- Update any existing README if needed"
            ),
            delay_after=3.0,
        ))
        wf3.add_step(WorkflowStep(
            name="4. Verify Refactoring",
            prompt=(
                "Verify the refactoring didn't break anything:\n"
                "- Run all existing tests\n"
                "- Check for compile errors\n"
                "- Ensure public API hasn't changed unexpectedly\n"
                "Provide a summary of improvements made with before/after comparison."
            ),
            delay_after=2.0,
        ))
        workflows["Code Review & Refactor"] = wf3

        # === Analyze, Fix & Sync ===
        wf4 = Workflow(
            name="Analyze, Fix & Sync",
            description="Continuous improvement: analyze needs → fix/refactor → GitHub sync"
        )
        wf4.add_step(WorkflowStep(
            name="1. Analyze Needs",
            prompt=(
                "Analyze the project at {project_path}. "
                "1. Run 'flutter analyze' and identify core issues.\n"
                "2. Check 'git status' for uncommitted changes.\n"
                "3. Identify what needs to be fixed, refactored, or organized."
            ),
            delay_after=5.0,
        ))
        wf4.add_step(WorkflowStep(
            name="2. Organize & Refactor",
            prompt=(
                "Based on the analysis, organize the file structure and fix issues. "
                "Move related widgets into subfolders, ensure coding standards are met, "
                "and fix any syntax or linting errors found."
            ),
            delay_after=10.0,
        ))
        wf4.add_step(WorkflowStep(
            name="3. Sync to GitHub",
            prompt=(
                "Commit all changes to the local repository with a clear message "
                "summarizing the fixes and organization done. "
                "Push the changes to the remote branch on GitHub."
            ),
            delay_after=5.0,
        ))
        workflows["Analyze, Fix & Sync"] = wf4

        return workflows

    def save_workflow(self, workflow: Workflow, save_dir: str) -> str:
        """Save a workflow to a JSON file"""
        os.makedirs(save_dir, exist_ok=True)
        safe_name = workflow.name.lower().replace(" ", "_").replace("/", "_")
        filepath = os.path.join(save_dir, f"workflow_{safe_name}.json")
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(workflow.to_dict(), f, indent=2, ensure_ascii=False)
        return filepath

    def load_workflow(self, filepath: str) -> Workflow:
        """Load a workflow from a JSON file"""
        with open(filepath, "r", encoding="utf-8") as f:
            data = json.load(f)
        return Workflow.from_dict(data)

    def load_all_saved(self, save_dir: str) -> Dict[str, Workflow]:
        """Load all saved workflows from a directory"""
        workflows = {}
        if not os.path.isdir(save_dir):
            return workflows
        for fname in os.listdir(save_dir):
            if fname.endswith(".json") and fname.startswith("workflow_"):
                try:
                    wf = self.load_workflow(os.path.join(save_dir, fname))
                    workflows[wf.name] = wf
                except Exception as e:
                    logger.warning(f"Failed to load workflow {fname}: {e}")
        return workflows


if __name__ == "__main__":
    # Quick self-test
    engine = WorkflowEngine()
    print(f"✅ WorkflowEngine loaded with {len(engine.builtin_workflows)} built-in workflows:")
    for name, wf in engine.builtin_workflows.items():
        print(f"   • {name} — {len(wf.steps)} steps — {wf.description}")
