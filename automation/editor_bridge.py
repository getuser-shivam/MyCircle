#!/usr/bin/env python3
"""
Editor Bridge — Sends prompts to AI coding editors.
Supports clipboard paste, task-file drop, auto-interact, and process launching.
"""

import os
import json
import subprocess
import time
import shutil
import threading
from pathlib import Path
from typing import Optional, List, Dict, Callable
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class EditorBridge:
    """Bridge to interact with AI coding editors"""

    EDITORS = {
        "antigravity": {
            "display": "Antigravity (Gemini)",
            "process_names": ["antigravity", "antigravity.exe"],
            "task_dir": ".gemini",
            "task_file": "task.md",
            "icon": "⚡",
            "chat_hotkey": "ctrl+shift+i",  # open AI chat panel
            "thinking_keywords": ["thinking", "generating", "loading", "processing"],
        },
        "windsurf": {
            "display": "Windsurf",
            "process_names": ["windsurf", "Windsurf.exe", "Code.exe"],
            "task_dir": ".windsurf/tasks",
            "task_file": "auto_prompt_task.md",
            "icon": "🌊",
            "chat_hotkey": "ctrl+l",  # open Cascade chat
            "thinking_keywords": ["thinking", "generating", "writing", "cascade"],
        },
        "cursor": {
            "display": "Cursor",
            "process_names": ["cursor", "Cursor.exe"],
            "task_dir": ".cursor",
            "task_file": "task.md",
            "icon": "🔮",
            "chat_hotkey": "ctrl+l",  # open chat
            "thinking_keywords": ["thinking", "generating", "loading"],
        },
        "clipboard": {
            "display": "Clipboard Only",
            "process_names": [],
            "task_dir": "",
            "task_file": "",
            "icon": "📋",
            "chat_hotkey": "",
            "thinking_keywords": [],
        },
    }

    def __init__(self, project_path: str = None, editor: str = "antigravity"):
        self.project_path = Path(project_path) if project_path else Path.cwd()
        self._editor = editor if editor in self.EDITORS else "antigravity"
        self._mode = "clipboard"  # clipboard | file_drop | terminal | auto_interact
        self._auto_focus = True
        self._log_history: List[Dict] = []

        # Auto-interact settings
        self._completion_timeout = 300  # max seconds to wait per step
        self._poll_interval = 2.0  # seconds between completion checks
        self._post_completion_delay = 2.0  # cooldown after AI finishes
        self._cancel_wait = threading.Event()  # to cancel waiting early

        # Status callback for GUI live updates
        self.on_status_change: Optional[Callable[[str, str], None]] = None  # (status, detail)

    @property
    def editor(self) -> str:
        return self._editor

    @editor.setter
    def editor(self, value: str):
        if value in self.EDITORS:
            self._editor = value

    @property
    def supported_editors(self) -> List[str]:
        return list(self.EDITORS.keys())

    @property
    def editor_display_name(self) -> str:
        return self.EDITORS[self._editor]["display"]

    @property
    def mode(self) -> str:
        return self._mode

    @mode.setter
    def mode(self, value: str):
        if value in ("clipboard", "file_drop", "terminal", "auto_interact"):
            self._mode = value

    def send_prompt(self, prompt: str) -> str:
        """Send a prompt to the selected editor using the configured mode"""
        timestamp = datetime.now().isoformat()

        try:
            if self._mode == "clipboard":
                result = self._send_via_clipboard(prompt)
            elif self._mode == "file_drop":
                result = self._send_via_file_drop(prompt)
            elif self._mode == "terminal":
                result = self._send_via_terminal(prompt)
            elif self._mode == "auto_interact":
                result = self._send_via_auto_interact(prompt)
            else:
                result = self._send_via_clipboard(prompt)

            self._log_history.append({
                "timestamp": timestamp,
                "editor": self._editor,
                "mode": self._mode,
                "prompt_preview": prompt[:100],
                "status": "sent",
                "result": result,
            })

            return result

        except Exception as e:
            error_msg = f"Failed to send prompt: {e}"
            self._log_history.append({
                "timestamp": timestamp,
                "editor": self._editor,
                "mode": self._mode,
                "prompt_preview": prompt[:100],
                "status": "error",
                "result": error_msg,
            })
            raise RuntimeError(error_msg)

    def send_and_wait(self, prompt: str) -> str:
        """Send a prompt via auto-interact and WAIT for the AI to finish responding.
        Returns only after the conversation is confirmed done."""
        self._cancel_wait.clear()
        self._emit_status("typing", "Typing prompt into editor...")

        # Step 1: Send the prompt into the editor chat
        send_result = self._send_via_auto_interact(prompt)

        # Step 2: Wait for the AI to finish responding
        self._emit_status("waiting", "Waiting for AI to finish...")
        done = self._wait_for_completion()

        if done == "cancelled":
            return f"{send_result} → ⏹ Wait cancelled"
        elif done == "timeout":
            return f"{send_result} → ⚠️ Timed out after {self._completion_timeout}s"

        # Step 3: Post-completion cooldown
        self._emit_status("cooldown", f"AI done. Cooling down {self._post_completion_delay}s...")
        time.sleep(self._post_completion_delay)

        self._emit_status("done", "Step complete")
        return f"{send_result} → ✅ AI conversation completed"

    def cancel_wait(self):
        """Cancel the current wait-for-completion"""
        self._cancel_wait.set()

    def _emit_status(self, status: str, detail: str):
        """Notify the GUI of status changes"""
        if self.on_status_change:
            try:
                self.on_status_change(status, detail)
            except Exception:
                pass

    def _send_via_clipboard(self, prompt: str) -> str:
        """Copy prompt to clipboard and optionally focus editor"""
        try:
            # Use a cross-platform clipboard approach
            # On Windows, use subprocess with clip
            process = subprocess.Popen(
                ["clip"],
                stdin=subprocess.PIPE,
                shell=True,
            )
            process.communicate(input=prompt.encode("utf-16le"))

            result = f"✅ Prompt copied to clipboard ({len(prompt)} chars)"

            # Try to focus the editor window
            if self._auto_focus:
                self._try_focus_editor()

            return result

        except Exception as e:
            # Fallback: try tkinter clipboard
            try:
                import tkinter as tk
                temp_root = tk.Tk()
                temp_root.withdraw()
                temp_root.clipboard_clear()
                temp_root.clipboard_append(prompt)
                temp_root.update()
                temp_root.destroy()
                return f"✅ Prompt copied to clipboard ({len(prompt)} chars)"
            except Exception:
                return f"⚠️ Clipboard copy failed: {e}. Prompt saved to file instead."

    def _send_via_file_drop(self, prompt: str) -> str:
        """Write prompt to a task file that the editor can pick up"""
        editor_config = self.EDITORS[self._editor]
        task_dir = editor_config.get("task_dir", "")

        if not task_dir:
            return self._send_via_clipboard(prompt)

        full_task_dir = self.project_path / task_dir
        full_task_dir.mkdir(parents=True, exist_ok=True)

        task_file = full_task_dir / editor_config["task_file"]
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        content = f"""# Auto-Prompt Task
> Generated: {timestamp}
> Editor: {editor_config['display']}

## Task

{prompt}

---
*Auto-generated by MyCircle Auto-Prompt Workflow Engine*
"""

        task_file.write_text(content, encoding="utf-8")

        # Also create a trigger file that some editors watch
        trigger_file = full_task_dir / ".auto_prompt_trigger"
        trigger_file.write_text(timestamp, encoding="utf-8")

        return f"✅ Task written to {task_file.relative_to(self.project_path)}"

    def _send_via_terminal(self, prompt: str) -> str:
        """Send prompt via terminal / stdin pipe (for CLI-based editors)"""
        # Write to a temp prompt file
        prompt_file = self.project_path / ".auto_prompt_current.txt"
        prompt_file.write_text(prompt, encoding="utf-8")

        return f"✅ Prompt saved to {prompt_file.name} for terminal ingestion"

    def _try_focus_editor(self):
        """Try to focus the editor window using Windows APIs"""
        try:
            import ctypes
            from ctypes import wintypes

            user32 = ctypes.windll.user32

            editor_config = self.EDITORS[self._editor]
            process_names = editor_config.get("process_names", [])

            # Try to find a window matching the editor
            # Simple approach: enumerate windows and find by title keywords
            keywords = {
                "antigravity": ["Antigravity", "antigravity"],
                "windsurf": ["Windsurf", "windsurf"],
                "cursor": ["Cursor", "cursor"],
            }

            search_terms = keywords.get(self._editor, [])
            if not search_terms:
                return

            EnumWindowsProc = ctypes.WINFUNCTYPE(
                wintypes.BOOL, wintypes.HWND, wintypes.LPARAM
            )

            found_hwnd = None

            def enum_callback(hwnd, lparam):
                nonlocal found_hwnd
                if user32.IsWindowVisible(hwnd):
                    length = user32.GetWindowTextLengthW(hwnd)
                    if length > 0:
                        buff = ctypes.create_unicode_buffer(length + 1)
                        user32.GetWindowTextW(hwnd, buff, length + 1)
                        title = buff.value
                        for term in search_terms:
                            if term.lower() in title.lower():
                                found_hwnd = hwnd
                                return False  # stop enumerating
                return True

            user32.EnumWindows(EnumWindowsProc(enum_callback), 0)

            if found_hwnd:
                user32.SetForegroundWindow(found_hwnd)
                logger.info(f"Focused editor window: {self._editor}")

        except Exception as e:
            logger.debug(f"Could not auto-focus editor: {e}")

    def is_editor_running(self) -> bool:
        """Check if the selected editor process is running"""
        editor_config = self.EDITORS[self._editor]
        process_names = editor_config.get("process_names", [])

        if not process_names:
            return True  # clipboard mode always available

        try:
            output = subprocess.check_output(
                ["tasklist", "/FI", "STATUS eq RUNNING"],
                shell=True, text=True, stderr=subprocess.DEVNULL
            )
            for pname in process_names:
                if pname.lower() in output.lower():
                    return True
        except Exception:
            pass

        return False

    def launch_editor(self, workspace_path: str = None) -> bool:
        """Attempt to launch the selected editor"""
        target = workspace_path or str(self.project_path)

        launch_commands = {
            "antigravity": ["antigravity", target],
            "windsurf": ["windsurf", target],
            "cursor": ["cursor", target],
        }

        cmd = launch_commands.get(self._editor)
        if not cmd:
            return False

        try:
            # Try to find the editor executable
            exe_path = shutil.which(cmd[0])
            if exe_path:
                subprocess.Popen([exe_path, target], shell=False)
                return True

            # Fallback: try common install paths on Windows
            common_paths = {
                "antigravity": [
                    os.path.expandvars(r"%LOCALAPPDATA%\Programs\antigravity\antigravity.exe"),
                ],
                "windsurf": [
                    os.path.expandvars(r"%LOCALAPPDATA%\Programs\Windsurf\Windsurf.exe"),
                    os.path.expandvars(r"%LOCALAPPDATA%\Programs\windsurf\windsurf.exe"),
                ],
                "cursor": [
                    os.path.expandvars(r"%LOCALAPPDATA%\Programs\cursor\Cursor.exe"),
                ],
            }

            for path in common_paths.get(self._editor, []):
                if os.path.isfile(path):
                    subprocess.Popen([path, target], shell=False)
                    return True

            logger.warning(f"Could not find {self._editor} executable")
            return False

        except Exception as e:
            logger.error(f"Failed to launch editor: {e}")
            return False

    def get_history(self) -> List[Dict]:
        """Return the send history"""
        return self._log_history.copy()

    def clear_history(self):
        """Clear the send history"""
        self._log_history.clear()

    # ═══════════════════════════════════════════════════
    # AUTO-INTERACT MODE
    # ═══════════════════════════════════════════════════
    def _send_via_auto_interact(self, prompt: str) -> str:
        """Focus editor, open chat panel, paste prompt, press Enter"""
        import ctypes
        from ctypes import wintypes

        editor_config = self.EDITORS[self._editor]
        user32 = ctypes.windll.user32

        # 1. Find and focus the editor window
        hwnd = self._find_editor_window()
        if not hwnd:
            # Try to launch the editor
            launched = self.launch_editor()
            if launched:
                time.sleep(5)  # wait for editor to start
                hwnd = self._find_editor_window()
            if not hwnd:
                return self._send_via_clipboard(prompt)  # fallback

        # Bring window to front
        user32.ShowWindow(hwnd, 9)  # SW_RESTORE
        time.sleep(0.2)
        user32.SetForegroundWindow(hwnd)
        time.sleep(0.5)

        # 2. Open chat panel with editor-specific hotkey
        chat_hotkey = editor_config.get("chat_hotkey", "")
        if chat_hotkey:
            self._press_hotkey(chat_hotkey)
            time.sleep(1.0)  # wait for panel to open

        # 3. Copy prompt to clipboard
        self._clipboard_set(prompt)
        time.sleep(0.2)

        # 4. Paste (Ctrl+V)
        self._press_hotkey("ctrl+v")
        time.sleep(0.5)

        # 5. Press Enter to submit
        self._press_key("enter")
        time.sleep(0.3)

        return f"✅ Prompt auto-typed into {editor_config['display']} ({len(prompt)} chars)"

    def _find_editor_window(self) -> Optional[int]:
        """Find the editor's main window handle"""
        try:
            import ctypes
            from ctypes import wintypes

            user32 = ctypes.windll.user32

            keywords = {
                "antigravity": ["Antigravity", "antigravity"],
                "windsurf": ["Windsurf", "windsurf"],
                "cursor": ["Cursor", "cursor"],
            }
            search_terms = keywords.get(self._editor, [])
            if not search_terms:
                return None

            EnumWindowsProc = ctypes.WINFUNCTYPE(
                wintypes.BOOL, wintypes.HWND, wintypes.LPARAM
            )

            found_hwnd = None

            def enum_callback(hwnd, lparam):
                nonlocal found_hwnd
                if user32.IsWindowVisible(hwnd):
                    length = user32.GetWindowTextLengthW(hwnd)
                    if length > 0:
                        buff = ctypes.create_unicode_buffer(length + 1)
                        user32.GetWindowTextW(hwnd, buff, length + 1)
                        title = buff.value
                        for term in search_terms:
                            if term.lower() in title.lower():
                                found_hwnd = hwnd
                                return False  # stop
                return True

            user32.EnumWindows(EnumWindowsProc(enum_callback), 0)
            return found_hwnd

        except Exception as e:
            logger.debug(f"Could not find editor window: {e}")
            return None

    def _get_window_title(self, hwnd) -> str:
        """Get the current title of a window"""
        try:
            import ctypes
            user32 = ctypes.windll.user32
            length = user32.GetWindowTextLengthW(hwnd)
            if length > 0:
                buff = ctypes.create_unicode_buffer(length + 1)
                user32.GetWindowTextW(hwnd, buff, length + 1)
                return buff.value
        except Exception:
            pass
        return ""

    def _wait_for_completion(self) -> str:
        """Wait for the AI conversation to finish.
        Returns: 'done', 'timeout', or 'cancelled'

        Detection strategy:
        1. Check if editor window title contains 'thinking/generating' keywords
        2. Monitor editor process CPU — high CPU = still working
        3. When title stabilizes AND CPU drops, conversation is done
        4. Fallback: timeout after _completion_timeout seconds
        """
        editor_config = self.EDITORS[self._editor]
        thinking_keywords = editor_config.get("thinking_keywords", [])
        start_time = time.time()

        hwnd = self._find_editor_window()

        # Wait a moment for the AI to start processing
        time.sleep(3.0)

        # Track title stability: must be stable for N consecutive checks
        stable_count = 0
        required_stable = 3  # must be stable for 3 x poll_interval
        last_title = ""
        was_thinking = False

        while True:
            elapsed = time.time() - start_time

            # Check cancel
            if self._cancel_wait.is_set():
                return "cancelled"

            # Check timeout
            if elapsed >= self._completion_timeout:
                return "timeout"

            # --- Detection Logic ---
            current_title = ""
            if hwnd:
                current_title = self._get_window_title(hwnd)

            # Check if title shows thinking/generating
            is_thinking = False
            for kw in thinking_keywords:
                if kw.lower() in current_title.lower():
                    is_thinking = True
                    was_thinking = True
                    break

            # Check process CPU usage
            cpu_busy = self._is_editor_cpu_busy()

            # Status update
            detail_parts = []
            if is_thinking:
                detail_parts.append("AI is thinking")
            if cpu_busy:
                detail_parts.append("high CPU")
            detail_parts.append(f"{int(elapsed)}s elapsed")
            self._emit_status("waiting", f"🔵 {' | '.join(detail_parts)}")

            # If NOT thinking AND CPU is low AND title is stable
            if not is_thinking and not cpu_busy:
                if current_title == last_title:
                    stable_count += 1
                else:
                    stable_count = 0

                # Require either: was_thinking and now stable, OR stable for longer
                if was_thinking and stable_count >= required_stable:
                    return "done"
                elif stable_count >= (required_stable + 3):  # extra patience if we never saw thinking
                    return "done"
            else:
                stable_count = 0

            last_title = current_title

            # Poll sleep (interruptible)
            if self._cancel_wait.wait(timeout=self._poll_interval):
                return "cancelled"

    def _is_editor_cpu_busy(self) -> bool:
        """Check if the editor process is using significant CPU.
        Returns True if CPU usage is above threshold (suggests still working)."""
        editor_config = self.EDITORS[self._editor]
        process_names = editor_config.get("process_names", [])

        if not process_names:
            return False

        try:
            # Use wmic for CPU check on Windows
            for pname in process_names:
                output = subprocess.check_output(
                    ["wmic", "process", "where",
                     f"name='{pname}'",
                     "get", "PercentProcessorTime"],
                    shell=True, text=True, stderr=subprocess.DEVNULL,
                    timeout=5,
                )
                for line in output.strip().split("\n"):
                    line = line.strip()
                    if line and line.isdigit():
                        cpu = int(line)
                        if cpu > 15:  # threshold: >15% = busy
                            return True
        except Exception:
            pass

        return False

    # ═══════════════════════════════════════════════════
    # KEYBOARD SIMULATION HELPERS
    # ═══════════════════════════════════════════════════
    def _press_hotkey(self, hotkey: str):
        """Press a hotkey combination like 'ctrl+l' or 'ctrl+shift+i'"""
        import ctypes

        VK_MAP = {
            "ctrl": 0x11, "shift": 0x10, "alt": 0x12,
            "enter": 0x0D, "tab": 0x09, "escape": 0x1B,
            "space": 0x20, "backspace": 0x08,
        }
        # Add letters a-z
        for c in "abcdefghijklmnopqrstuvwxyz":
            VK_MAP[c] = ord(c.upper())
        # Add v specifically for Ctrl+V
        VK_MAP["v"] = 0x56

        KEYEVENTF_KEYUP = 0x0002
        user32 = ctypes.windll.user32

        keys = [k.strip().lower() for k in hotkey.split("+")]
        vk_codes = [VK_MAP.get(k, 0) for k in keys]

        # Press down all keys
        for vk in vk_codes:
            if vk:
                user32.keybd_event(vk, 0, 0, 0)
                time.sleep(0.05)

        # Release all keys in reverse
        for vk in reversed(vk_codes):
            if vk:
                user32.keybd_event(vk, 0, KEYEVENTF_KEYUP, 0)
                time.sleep(0.05)

    def _press_key(self, key: str):
        """Press a single key"""
        self._press_hotkey(key)

    def _clipboard_set(self, text: str):
        """Set clipboard content"""
        try:
            process = subprocess.Popen(
                ["clip"], stdin=subprocess.PIPE, shell=True,
            )
            process.communicate(input=text.encode("utf-16le"))
        except Exception:
            # Fallback: tkinter
            try:
                import tkinter as tk
                r = tk.Tk()
                r.withdraw()
                r.clipboard_clear()
                r.clipboard_append(text)
                r.update()
                r.destroy()
            except Exception:
                pass


if __name__ == "__main__":
    bridge = EditorBridge()
    print(f"✅ EditorBridge loaded")
    print(f"   Supported editors: {bridge.supported_editors}")
    print(f"   Modes: clipboard | file_drop | terminal | auto_interact")
    for key, config in EditorBridge.EDITORS.items():
        hotkey = config.get('chat_hotkey', 'N/A')
        print(f"   {config['icon']} {config['display']} ({key}) — chat: {hotkey}")
