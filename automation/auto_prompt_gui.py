#!/usr/bin/env python3
"""
Auto-Prompt Workflow GUI
Chains prompts sequentially and sends them to AI coding editors
for hands-free, automated development.
"""

import tkinter as tk
from tkinter import ttk, scrolledtext, messagebox, filedialog
import threading
import os
import sys
import json
from pathlib import Path
from datetime import datetime
from typing import Optional

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from workflow_engine import WorkflowEngine, Workflow, WorkflowStep
from editor_bridge import EditorBridge

# ─────────────────────────────────────────────────────
# Color Palette
# ─────────────────────────────────────────────────────
COLORS = {
    "bg_dark": "#0d1117",
    "bg_mid": "#161b22",
    "bg_card": "#1c2128",
    "bg_input": "#21262d",
    "bg_hover": "#282e36",
    "border": "#30363d",
    "border_light": "#3d444d",
    "text": "#e6edf3",
    "text_dim": "#8b949e",
    "text_muted": "#6e7681",
    "accent": "#58a6ff",
    "accent_hover": "#79c0ff",
    "green": "#3fb950",
    "green_dim": "#1a7f37",
    "red": "#f85149",
    "red_dim": "#a4252a",
    "yellow": "#d29922",
    "purple": "#bc8cff",
    "orange": "#f0883e",
    "cyan": "#39d2c0",
}

STATUS_COLORS = {
    "pending": COLORS["text_muted"],
    "running": COLORS["accent"],
    "completed": COLORS["green"],
    "failed": COLORS["red"],
    "skipped": COLORS["text_dim"],
}

STATUS_ICONS = {
    "pending": "○",
    "running": "⏳",
    "completed": "✅",
    "failed": "❌",
    "skipped": "⏭️",
}


class AutoPromptGUI:
    """Modern dark-themed GUI for auto-prompt workflow execution"""

    WORKFLOW_SAVE_DIR = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "workflows"
    )

    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("⚡ Auto-Prompt Workflow Runner")
        self.root.geometry("1100x780")
        self.root.minsize(900, 600)
        self.root.configure(bg=COLORS["bg_dark"])

        # Engine & Bridge
        self.engine = WorkflowEngine()
        self.bridge = EditorBridge(
            project_path=str(Path.cwd().parent),
            editor="antigravity",
        )

        # Bind engine callbacks
        self.engine.on_step_start = self._on_step_start
        self.engine.on_step_complete = self._on_step_complete
        self.engine.on_workflow_done = self._on_workflow_done
        self.engine.on_error = self._on_step_error
        self.engine.on_progress = self._on_progress
        self.engine.send_prompt_fn = self.bridge.send_prompt
        self.engine.on_loop_wait = self._on_loop_wait

        # Bridge status callback for live AI status
        self.bridge.on_status_change = self._on_bridge_status

        # State
        self._active_workflow: Optional[Workflow] = None
        self._step_frames = []
        self._all_workflows = dict(self.engine.builtin_workflows)
        self._auto_launch_var = tk.BooleanVar(value=True)
        self._auto_focus_var = tk.BooleanVar(value=True)
        self._custom_hotkey_var = tk.StringVar(value="")
        self._step_cooldown_var = tk.StringVar(value="")  # Empty = use default
        self._loop_var = tk.BooleanVar(value=False)
        self._loop_interval_var = tk.StringVar(value="2")  # 2 mins
        # load saved
        saved = self.engine.load_all_saved(self.WORKFLOW_SAVE_DIR)
        self._all_workflows.update(saved)

        # Build UI
        self._setup_styles()
        self._build_ui()
        self._populate_workflow_list()

        # Select first workflow
        if self._all_workflows:
            first_name = list(self._all_workflows.keys())[0]
            self._select_workflow(first_name)

        # Try to load project path from .env
        self._load_project_path()

    # ═══════════════════════════════════════════════════
    # STYLES
    # ═══════════════════════════════════════════════════
    def _setup_styles(self):
        style = ttk.Style()
        style.theme_use("clam")

        # Global background
        style.configure(".", background=COLORS["bg_dark"], foreground=COLORS["text"],
                         borderwidth=0, focuscolor=COLORS["accent"])

        # Frames
        style.configure("Dark.TFrame", background=COLORS["bg_dark"])
        style.configure("Card.TFrame", background=COLORS["bg_card"])
        style.configure("Mid.TFrame", background=COLORS["bg_mid"])

        # Labels
        style.configure("Title.TLabel", background=COLORS["bg_dark"],
                         foreground=COLORS["text"], font=("Segoe UI", 18, "bold"))
        style.configure("Subtitle.TLabel", background=COLORS["bg_dark"],
                         foreground=COLORS["text_dim"], font=("Segoe UI", 10))
        style.configure("Card.TLabel", background=COLORS["bg_card"],
                         foreground=COLORS["text"], font=("Segoe UI", 10))
        style.configure("CardTitle.TLabel", background=COLORS["bg_card"],
                         foreground=COLORS["text"], font=("Segoe UI", 11, "bold"))
        style.configure("Mid.TLabel", background=COLORS["bg_mid"],
                         foreground=COLORS["text"], font=("Segoe UI", 10))
        style.configure("Dim.TLabel", background=COLORS["bg_dark"],
                         foreground=COLORS["text_dim"], font=("Segoe UI", 9))
        style.configure("Accent.TLabel", background=COLORS["bg_dark"],
                         foreground=COLORS["accent"], font=("Segoe UI", 10, "bold"))

        # Buttons
        style.configure("Action.TButton", background=COLORS["accent"],
                         foreground="#ffffff", font=("Segoe UI", 10, "bold"),
                         padding=(14, 6))
        style.map("Action.TButton",
                   background=[("active", COLORS["accent_hover"])],
                   foreground=[("active", "#ffffff")])

        style.configure("Danger.TButton", background=COLORS["red_dim"],
                         foreground="#ffffff", font=("Segoe UI", 10, "bold"),
                         padding=(14, 6))
        style.map("Danger.TButton",
                   background=[("active", COLORS["red"])])

        style.configure("Ghost.TButton", background=COLORS["bg_mid"],
                         foreground=COLORS["text_dim"], font=("Segoe UI", 9),
                         padding=(8, 4))
        style.map("Ghost.TButton",
                   background=[("active", COLORS["bg_hover"])],
                   foreground=[("active", COLORS["text"])])

        style.configure("Sidebar.TButton", background=COLORS["bg_mid"],
                         foreground=COLORS["text"], font=("Segoe UI", 10),
                         padding=(10, 8), anchor="w")
        style.map("Sidebar.TButton",
                   background=[("active", COLORS["bg_hover"])])

        style.configure("SidebarActive.TButton", background=COLORS["bg_card"],
                         foreground=COLORS["accent"], font=("Segoe UI", 10, "bold"),
                         padding=(10, 8), anchor="w")

        # Entry
        style.configure("Dark.TEntry", fieldbackground=COLORS["bg_input"],
                         foreground=COLORS["text"], insertcolor=COLORS["text"],
                         borderwidth=1, relief="solid")

        # Combobox
        style.configure("Dark.TCombobox", fieldbackground=COLORS["bg_input"],
                         foreground=COLORS["text"],
                         selectbackground=COLORS["accent"],
                         selectforeground="#ffffff")
        style.map("Dark.TCombobox",
                   fieldbackground=[("readonly", COLORS["bg_input"])],
                   foreground=[("readonly", COLORS["text"])])

        # Progressbar
        style.configure("Accent.Horizontal.TProgressbar",
                         troughcolor=COLORS["bg_input"],
                         background=COLORS["accent"],
                         darkcolor=COLORS["accent"],
                         lightcolor=COLORS["accent_hover"],
                         bordercolor=COLORS["border"],
                         thickness=6)

        # Separator
        style.configure("Dark.TSeparator", background=COLORS["border"])

        # LabelFrame
        style.configure("Card.TLabelframe", background=COLORS["bg_card"],
                         foreground=COLORS["text_dim"],
                         bordercolor=COLORS["border"])
        style.configure("Card.TLabelframe.Label", background=COLORS["bg_card"],
                         foreground=COLORS["text_dim"],
                         font=("Segoe UI", 9, "bold"))

    # ═══════════════════════════════════════════════════
    # BUILD UI
    # ═══════════════════════════════════════════════════
    def _build_ui(self):
        # ── Top Bar ──
        top_bar = tk.Frame(self.root, bg=COLORS["bg_mid"], height=56)
        top_bar.pack(fill=tk.X, side=tk.TOP)
        top_bar.pack_propagate(False)

        tk.Label(top_bar, text="⚡", font=("Segoe UI", 20),
                 bg=COLORS["bg_mid"], fg=COLORS["yellow"]).pack(side=tk.LEFT, padx=(16, 4))
        tk.Label(top_bar, text="Auto-Prompt Workflow Runner", font=("Segoe UI", 14, "bold"),
                 bg=COLORS["bg_mid"], fg=COLORS["text"]).pack(side=tk.LEFT)
        tk.Label(top_bar, text="Chain prompts → Auto develop", font=("Segoe UI", 9),
                 bg=COLORS["bg_mid"], fg=COLORS["text_dim"]).pack(side=tk.LEFT, padx=(12, 0))

        # Settings button
        settings_btn = tk.Button(
            top_bar, text="⚙ Settings", font=("Segoe UI", 9),
            bg=COLORS["bg_card"], fg=COLORS["text_dim"],
            activebackground=COLORS["bg_hover"], activeforeground=COLORS["text"],
            relief="flat", bd=0, padx=12, pady=4,
            command=self._show_settings,
        )
        settings_btn.pack(side=tk.RIGHT, padx=16)

        # ── Main horizontal split ──
        main = tk.PanedWindow(self.root, orient=tk.HORIZONTAL,
                               bg=COLORS["border"], sashwidth=2, sashrelief="flat")
        main.pack(fill=tk.BOTH, expand=True, padx=0, pady=0)

        # ── LEFT: Workflow Sidebar ──
        sidebar = tk.Frame(main, bg=COLORS["bg_mid"], width=220)
        main.add(sidebar, minsize=180, width=220)

        sidebar_header = tk.Frame(sidebar, bg=COLORS["bg_mid"])
        sidebar_header.pack(fill=tk.X, padx=12, pady=(14, 6))
        tk.Label(sidebar_header, text="WORKFLOWS", font=("Segoe UI", 9, "bold"),
                 bg=COLORS["bg_mid"], fg=COLORS["text_dim"]).pack(side=tk.LEFT)

        add_btn = tk.Button(
            sidebar_header, text="+ New", font=("Segoe UI", 8, "bold"),
            bg=COLORS["green_dim"], fg=COLORS["green"],
            activebackground=COLORS["green"], activeforeground="#ffffff",
            relief="flat", bd=0, padx=8, pady=2,
            command=self._new_workflow,
        )
        add_btn.pack(side=tk.RIGHT)

        # Scrollable workflow list
        self._sidebar_list_frame = tk.Frame(sidebar, bg=COLORS["bg_mid"])
        self._sidebar_list_frame.pack(fill=tk.BOTH, expand=True, padx=8, pady=4)

        # ── RIGHT: Main content area ──
        right = tk.Frame(main, bg=COLORS["bg_dark"])
        main.add(right, minsize=600)

        # ── Right top split: config bar + steps ──
        # Config bar
        config_bar = tk.Frame(right, bg=COLORS["bg_card"], height=50)
        config_bar.pack(fill=tk.X, padx=12, pady=(10, 0))
        config_bar.pack_propagate(False)

        # Project path
        tk.Label(config_bar, text="📁 Project:", font=("Segoe UI", 9),
                 bg=COLORS["bg_card"], fg=COLORS["text_dim"]).pack(side=tk.LEFT, padx=(10, 4))
        self._project_var = tk.StringVar(value=str(Path.cwd().parent))
        project_entry = tk.Entry(
            config_bar, textvariable=self._project_var,
            font=("Segoe UI", 9), bg=COLORS["bg_input"],
            fg=COLORS["text"], insertbackground=COLORS["text"],
            relief="flat", bd=0,
        )
        project_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 6), ipady=3)

        browse_btn = tk.Button(
            config_bar, text="Browse", font=("Segoe UI", 8),
            bg=COLORS["bg_input"], fg=COLORS["text_dim"],
            activebackground=COLORS["bg_hover"], activeforeground=COLORS["text"],
            relief="flat", bd=0, padx=8,
            command=self._browse_project,
        )
        browse_btn.pack(side=tk.LEFT, padx=(0, 8))

        # Editor selector
        tk.Label(config_bar, text="Editor:", font=("Segoe UI", 9),
                 bg=COLORS["bg_card"], fg=COLORS["text_dim"]).pack(side=tk.LEFT, padx=(8, 4))
        self._editor_var = tk.StringVar(value="antigravity")
        editor_combo = ttk.Combobox(
            config_bar, textvariable=self._editor_var,
            values=self.bridge.supported_editors,
            state="readonly", width=14, style="Dark.TCombobox",
        )
        editor_combo.pack(side=tk.LEFT, padx=(0, 8))
        editor_combo.bind("<<ComboboxSelected>>", self._on_editor_change)

        # Send mode
        tk.Label(config_bar, text="Mode:", font=("Segoe UI", 9),
                 bg=COLORS["bg_card"], fg=COLORS["text_dim"]).pack(side=tk.LEFT, padx=(8, 4))
        self._mode_var = tk.StringVar(value="clipboard")
        mode_combo = ttk.Combobox(
            config_bar, textvariable=self._mode_var,
            values=["clipboard", "file_drop", "terminal", "auto_interact"],
            state="readonly", width=12, style="Dark.TCombobox",
        )
        mode_combo.pack(side=tk.LEFT, padx=(0, 10))
        mode_combo.bind("<<ComboboxSelected>>", self._on_mode_change)

        # Step Cooldown (Global)
        tk.Label(config_bar, text="Step Cooldown (s):", font=("Segoe UI", 9),
                 bg=COLORS["bg_card"], fg=COLORS["text_dim"]).pack(side=tk.LEFT, padx=(8, 4))
        tk.Entry(config_bar, textvariable=self._step_cooldown_var, width=5,
                 font=("Cascadia Code", 9), bg=COLORS["bg_input"], fg=COLORS["text"],
                 relief="flat", justify="center").pack(side=tk.LEFT, padx=(0, 8))

        # ── Vertical split: steps editor on top, execution log on bottom ──
        content_pane = tk.PanedWindow(right, orient=tk.VERTICAL,
                                       bg=COLORS["border"], sashwidth=2, sashrelief="flat")
        content_pane.pack(fill=tk.BOTH, expand=True, padx=12, pady=8)

        # ── STEP EDITOR ──
        steps_outer = tk.Frame(content_pane, bg=COLORS["bg_card"])
        content_pane.add(steps_outer, minsize=200, height=340)

        steps_header = tk.Frame(steps_outer, bg=COLORS["bg_card"])
        steps_header.pack(fill=tk.X, padx=12, pady=(10, 4))

        self._wf_title_label = tk.Label(
            steps_header, text="Select a workflow",
            font=("Segoe UI", 13, "bold"), bg=COLORS["bg_card"], fg=COLORS["text"],
        )
        self._wf_title_label.pack(side=tk.LEFT)

        self._wf_desc_label = tk.Label(
            steps_header, text="",
            font=("Segoe UI", 9), bg=COLORS["bg_card"], fg=COLORS["text_dim"],
        )
        self._wf_desc_label.pack(side=tk.LEFT, padx=(12, 0))

        # Workflow actions row
        wf_actions = tk.Frame(steps_outer, bg=COLORS["bg_card"])
        wf_actions.pack(fill=tk.X, padx=12, pady=(0, 6))

        add_step_btn = tk.Button(
            wf_actions, text="+ Add Step", font=("Segoe UI", 9, "bold"),
            bg=COLORS["green_dim"], fg=COLORS["green"],
            activebackground=COLORS["green"], activeforeground="#ffffff",
            relief="flat", bd=0, padx=10, pady=3,
            command=self._add_step,
        )
        add_step_btn.pack(side=tk.LEFT)

        # Variables button
        vars_btn = tk.Button(
            wf_actions, text="{ } Variables", font=("Segoe UI", 9),
            bg=COLORS["bg_input"], fg=COLORS["text_dim"],
            activebackground=COLORS["bg_hover"], activeforeground=COLORS["text"],
            relief="flat", bd=0, padx=10, pady=3,
            command=self._edit_variables,
        )
        vars_btn.pack(side=tk.LEFT, padx=(8, 0))

        save_wf_btn = tk.Button(
            wf_actions, text="💾 Save", font=("Segoe UI", 9),
            bg=COLORS["bg_input"], fg=COLORS["text_dim"],
            activebackground=COLORS["bg_hover"], activeforeground=COLORS["text"],
            relief="flat", bd=0, padx=10, pady=3,
            command=self._save_current_workflow,
        )
        save_wf_btn.pack(side=tk.LEFT, padx=(8, 0))

        delete_wf_btn = tk.Button(
            wf_actions, text="🗑 Delete Workflow", font=("Segoe UI", 9),
            bg=COLORS["bg_input"], fg=COLORS["red"],
            activebackground=COLORS["red_dim"], activeforeground="#ffffff",
            relief="flat", bd=0, padx=10, pady=3,
            command=self._delete_workflow,
        )
        delete_wf_btn.pack(side=tk.RIGHT)

        # Step delay 
        tk.Label(wf_actions, text="Delay (s):", font=("Segoe UI", 9),
                 bg=COLORS["bg_card"], fg=COLORS["text_dim"]).pack(side=tk.RIGHT, padx=(0, 4))
        self._delay_var = tk.StringVar(value="5")
        delay_entry = tk.Entry(
            wf_actions, textvariable=self._delay_var, width=4,
            font=("Segoe UI", 9), bg=COLORS["bg_input"],
            fg=COLORS["text"], insertbackground=COLORS["text"],
            relief="flat", bd=0, justify="center",
        )
        delay_entry.pack(side=tk.RIGHT, padx=(0, 8), ipady=2)

        # Scrollable steps list
        steps_canvas_frame = tk.Frame(steps_outer, bg=COLORS["bg_card"])
        steps_canvas_frame.pack(fill=tk.BOTH, expand=True, padx=6, pady=(0, 8))

        self._steps_canvas = tk.Canvas(
            steps_canvas_frame, bg=COLORS["bg_card"],
            highlightthickness=0, bd=0,
        )
        steps_scrollbar = ttk.Scrollbar(steps_canvas_frame, orient="vertical",
                                         command=self._steps_canvas.yview)
        self._steps_inner = tk.Frame(self._steps_canvas, bg=COLORS["bg_card"])
        self._steps_inner.bind("<Configure>",
                                lambda e: self._steps_canvas.configure(
                                    scrollregion=self._steps_canvas.bbox("all")))

        self._steps_canvas_window = self._steps_canvas.create_window(
            (0, 0), window=self._steps_inner, anchor="nw"
        )
        self._steps_canvas.configure(yscrollcommand=steps_scrollbar.set)

        self._steps_canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        steps_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Make canvas resize inner frame width
        self._steps_canvas.bind("<Configure>", self._on_canvas_resize)

        # Mouse wheel scrolling
        self._steps_canvas.bind_all("<MouseWheel>",
                                     lambda e: self._steps_canvas.yview_scroll(
                                         int(-1 * (e.delta / 120)), "units"))

        # ── EXECUTION LOG ──
        exec_outer = tk.Frame(content_pane, bg=COLORS["bg_mid"])
        content_pane.add(exec_outer, minsize=180)

        exec_header = tk.Frame(exec_outer, bg=COLORS["bg_mid"])
        exec_header.pack(fill=tk.X, padx=12, pady=(10, 4))

        tk.Label(exec_header, text="EXECUTION LOG", font=("Segoe UI", 9, "bold"),
                 bg=COLORS["bg_mid"], fg=COLORS["text_dim"]).pack(side=tk.LEFT)

        # Live AI status indicator
        self._ai_status_var = tk.StringVar(value="")
        self._ai_status_label = tk.Label(
            exec_header, textvariable=self._ai_status_var,
            font=("Segoe UI", 9, "bold"), bg=COLORS["bg_mid"], fg=COLORS["cyan"],
        )
        self._ai_status_label.pack(side=tk.LEFT, padx=(12, 0))

        # Controls
        ctrl_frame = tk.Frame(exec_header, bg=COLORS["bg_mid"])
        ctrl_frame.pack(side=tk.RIGHT)

        self._run_btn = tk.Button(
            ctrl_frame, text="▶  Run", font=("Segoe UI", 10, "bold"),
            bg=COLORS["green_dim"], fg=COLORS["green"],
            activebackground=COLORS["green"], activeforeground="#ffffff",
            relief="flat", bd=0, padx=14, pady=4,
            command=self._run_workflow,
        )
        self._run_btn.pack(side=tk.LEFT, padx=(0, 6))

        self._pause_btn = tk.Button(
            ctrl_frame, text="⏸ Pause", font=("Segoe UI", 10),
            bg=COLORS["bg_card"], fg=COLORS["yellow"],
            activebackground=COLORS["yellow"], activeforeground="#000000",
            relief="flat", bd=0, padx=14, pady=4,
            command=self._pause_resume,
            state="disabled",
        )
        self._pause_btn.pack(side=tk.LEFT, padx=(0, 6))

        self._stop_btn = tk.Button(
            ctrl_frame, text="⏹ Stop", font=("Segoe UI", 10),
            bg=COLORS["bg_card"], fg=COLORS["red"],
            activebackground=COLORS["red"], activeforeground="#ffffff",
            relief="flat", bd=0, padx=14, pady=4,
            command=self._stop_workflow,
            state="disabled",
        )
        self._stop_btn.pack(side=tk.LEFT, padx=(0, 6))

        clear_btn = tk.Button(
            ctrl_frame, text="Clear", font=("Segoe UI", 9),
            bg=COLORS["bg_card"], fg=COLORS["text_dim"],
            activebackground=COLORS["bg_hover"], activeforeground=COLORS["text"],
            relief="flat", bd=0, padx=10, pady=4,
            command=self._clear_log,
        )
        clear_btn.pack(side=tk.LEFT)

        # Loop Controls row
        loop_row = tk.Frame(exec_outer, bg=COLORS["bg_mid"])
        loop_row.pack(fill=tk.X, padx=12, pady=(0, 6))

        tk.Checkbutton(
            loop_row, text="Auto Sync (Loop)", variable=self._loop_var,
            bg=COLORS["bg_mid"], fg=COLORS["text"],
            selectcolor=COLORS["bg_dark"], activebackground=COLORS["bg_mid"],
            font=("Segoe UI", 9, "bold")
        ).pack(side=tk.LEFT)

        tk.Label(loop_row, text="Interval (min):", font=("Segoe UI", 9),
                 bg=COLORS["bg_mid"], fg=COLORS["text_dim"]).pack(side=tk.LEFT, padx=(12, 4))
        
        tk.Entry(
            loop_row, textvariable=self._loop_interval_var, width=5,
            font=("Segoe UI", 9), bg=COLORS["bg_input"],
            fg=COLORS["text"], insertbackground=COLORS["text"],
            relief="flat", bd=0, justify="center"
        ).pack(side=tk.LEFT, ipady=2)

        # Progress bar
        prog_frame = tk.Frame(exec_outer, bg=COLORS["bg_mid"])
        prog_frame.pack(fill=tk.X, padx=12, pady=(0, 4))
        self._progress_var = tk.DoubleVar(value=0)
        self._progress_bar = ttk.Progressbar(
            prog_frame, variable=self._progress_var,
            maximum=100, style="Accent.Horizontal.TProgressbar",
        )
        self._progress_bar.pack(fill=tk.X)

        # Log text
        self._log_text = tk.Text(
            exec_outer, wrap=tk.WORD,
            bg=COLORS["bg_dark"], fg=COLORS["text"],
            font=("Cascadia Code", 9), relief="flat", bd=0,
            insertbackground=COLORS["text"],
            selectbackground=COLORS["accent"],
            padx=12, pady=8,
        )
        self._log_text.pack(fill=tk.BOTH, expand=True, padx=8, pady=(0, 8))

        # Log tags
        self._log_text.tag_configure("timestamp", foreground=COLORS["text_muted"])
        self._log_text.tag_configure("info", foreground=COLORS["accent"])
        self._log_text.tag_configure("success", foreground=COLORS["green"])
        self._log_text.tag_configure("error", foreground=COLORS["red"])
        self._log_text.tag_configure("warning", foreground=COLORS["yellow"])
        self._log_text.tag_configure("step", foreground=COLORS["purple"])
        self._log_text.tag_configure("dim", foreground=COLORS["text_dim"])

        # Status bar
        status_bar = tk.Frame(self.root, bg=COLORS["bg_mid"], height=28)
        status_bar.pack(fill=tk.X, side=tk.BOTTOM)
        status_bar.pack_propagate(False)

        self._status_var = tk.StringVar(value="Ready")
        tk.Label(status_bar, textvariable=self._status_var, font=("Segoe UI", 8),
                 bg=COLORS["bg_mid"], fg=COLORS["text_dim"]).pack(side=tk.LEFT, padx=12)

        self._editor_status = tk.Label(
            status_bar, text="⚡ Antigravity", font=("Segoe UI", 8, "bold"),
            bg=COLORS["bg_mid"], fg=COLORS["accent"],
        )
        self._editor_status.pack(side=tk.RIGHT, padx=12)

    # ═══════════════════════════════════════════════════
    # CANVAS HELPERS
    # ═══════════════════════════════════════════════════
    def _on_canvas_resize(self, event):
        self._steps_canvas.itemconfig(self._steps_canvas_window, width=event.width)

    # ═══════════════════════════════════════════════════
    # SIDEBAR
    # ═══════════════════════════════════════════════════
    def _populate_workflow_list(self):
        for child in self._sidebar_list_frame.winfo_children():
            child.destroy()

        for name, wf in self._all_workflows.items():
            is_active = (self._active_workflow and self._active_workflow.name == name)
            btn_bg = COLORS["bg_card"] if is_active else COLORS["bg_mid"]
            btn_fg = COLORS["accent"] if is_active else COLORS["text"]
            btn_font = ("Segoe UI", 10, "bold") if is_active else ("Segoe UI", 10)

            btn_frame = tk.Frame(self._sidebar_list_frame, bg=btn_bg, cursor="hand2")
            btn_frame.pack(fill=tk.X, pady=2, ipady=6)

            # Left accent bar for active
            if is_active:
                accent_bar = tk.Frame(btn_frame, bg=COLORS["accent"], width=3)
                accent_bar.pack(side=tk.LEFT, fill=tk.Y)

            icon = "▶" if is_active else "○"
            label = tk.Label(
                btn_frame, text=f"  {icon}  {name}",
                font=btn_font, bg=btn_bg, fg=btn_fg,
                anchor="w",
            )
            label.pack(fill=tk.X, padx=4)

            desc = tk.Label(
                btn_frame, text=f"     {len(wf.steps)} steps",
                font=("Segoe UI", 8), bg=btn_bg, fg=COLORS["text_muted"],
                anchor="w",
            )
            desc.pack(fill=tk.X, padx=4)

            # Click handler
            for widget in (btn_frame, label, desc):
                widget.bind("<Button-1>", lambda e, n=name: self._select_workflow(n))

    def _select_workflow(self, name: str):
        if name in self._all_workflows:
            self._active_workflow = self._all_workflows[name]
            self._wf_title_label.config(text=self._active_workflow.name)
            self._wf_desc_label.config(text=self._active_workflow.description)
            self._render_steps()
            self._populate_workflow_list()

    # ═══════════════════════════════════════════════════
    # STEP EDITOR
    # ═══════════════════════════════════════════════════
    def _render_steps(self):
        """Render all steps of the active workflow in the editor"""
        for child in self._steps_inner.winfo_children():
            child.destroy()
        self._step_frames.clear()

        if not self._active_workflow:
            return

        for i, step in enumerate(self._active_workflow.steps):
            self._create_step_card(i, step)

    def _create_step_card(self, index: int, step: WorkflowStep):
        """Create a single step card widget"""
        status_color = STATUS_COLORS.get(step.status, COLORS["text_muted"])
        status_icon = STATUS_ICONS.get(step.status, "○")

        card = tk.Frame(self._steps_inner, bg=COLORS["bg_input"], bd=0,
                         highlightbackground=COLORS["border"], highlightthickness=1)
        card.pack(fill=tk.X, padx=6, pady=3, ipady=4)

        # Header row
        header = tk.Frame(card, bg=COLORS["bg_input"])
        header.pack(fill=tk.X, padx=8, pady=(6, 2))

        # Status dot
        tk.Label(header, text=status_icon, font=("Segoe UI", 10),
                 bg=COLORS["bg_input"], fg=status_color).pack(side=tk.LEFT, padx=(0, 6))

        # Step name — editable
        name_var = tk.StringVar(value=step.name)
        name_entry = tk.Entry(
            header, textvariable=name_var,
            font=("Segoe UI", 10, "bold"), bg=COLORS["bg_input"],
            fg=COLORS["text"], insertbackground=COLORS["text"],
            relief="flat", bd=0,
        )
        name_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        name_var.trace_add("write", lambda *a, i=index, v=name_var: self._update_step_name(i, v.get()))

        enabled_var = tk.BooleanVar(value=step.enabled)
        enabled_cb = tk.Checkbutton(
            header, text="Enabled", variable=enabled_var,
            bg=COLORS["bg_input"], fg=COLORS["text_dim"],
            selectcolor=COLORS["bg_dark"], activebackground=COLORS["bg_input"],
            font=("Segoe UI", 8),
            command=lambda i=index, v=enabled_var: self._toggle_step(i, v.get()),
        )
        enabled_cb.pack(side=tk.RIGHT, padx=(4, 0))

        # Delay input
        tk.Label(header, text="Delay(s):", font=("Segoe UI", 8),
                 bg=COLORS["bg_input"], fg=COLORS["text_dim"]).pack(side=tk.RIGHT, padx=(4, 0))
        delay_var = tk.StringVar(value=str(step.delay_after))
        delay_entry = tk.Entry(
            header, textvariable=delay_var, width=4,
            font=("Segoe UI", 8), bg=COLORS["bg_input"],
            fg=COLORS["text"], insertbackground=COLORS["text"],
            relief="flat", bd=0, justify="center"
        )
        delay_entry.pack(side=tk.RIGHT, padx=(0, 2))
        delay_var.trace_add("write", lambda *a, i=index, v=delay_var: self._update_step_delay(i, v.get()))

        # Move / delete buttons
        btn_frame = tk.Frame(header, bg=COLORS["bg_input"])
        btn_frame.pack(side=tk.RIGHT, padx=(8, 0))

        if index > 0:
            tk.Button(
                btn_frame, text="↑", font=("Segoe UI", 9),
                bg=COLORS["bg_input"], fg=COLORS["text_dim"],
                activebackground=COLORS["bg_hover"],
                relief="flat", bd=0, padx=4,
                command=lambda i=index: self._move_step(i, i - 1),
            ).pack(side=tk.LEFT)

        if index < len(self._active_workflow.steps) - 1:
            tk.Button(
                btn_frame, text="↓", font=("Segoe UI", 9),
                bg=COLORS["bg_input"], fg=COLORS["text_dim"],
                activebackground=COLORS["bg_hover"],
                relief="flat", bd=0, padx=4,
                command=lambda i=index: self._move_step(i, i + 1),
            ).pack(side=tk.LEFT)

        tk.Button(
            btn_frame, text="✕", font=("Segoe UI", 9),
            bg=COLORS["bg_input"], fg=COLORS["red"],
            activebackground=COLORS["red_dim"],
            relief="flat", bd=0, padx=4,
            command=lambda i=index: self._remove_step(i),
        ).pack(side=tk.LEFT, padx=(4, 0))

        # Prompt text area
        prompt_text = tk.Text(
            card, height=3, wrap=tk.WORD,
            bg=COLORS["bg_dark"], fg=COLORS["text"],
            font=("Cascadia Code", 9), relief="flat", bd=0,
            insertbackground=COLORS["text"],
            selectbackground=COLORS["accent"],
            padx=8, pady=4,
        )
        prompt_text.pack(fill=tk.X, padx=8, pady=(2, 8))
        prompt_text.insert("1.0", step.prompt)
        prompt_text.bind("<KeyRelease>",
                          lambda e, i=index, t=prompt_text: self._update_step_prompt(i, t))

        self._step_frames.append(card)

    def _update_step_name(self, index: int, name: str):
        if self._active_workflow and 0 <= index < len(self._active_workflow.steps):
            self._active_workflow.steps[index].name = name

    def _update_step_prompt(self, index: int, text_widget: tk.Text):
        if self._active_workflow and 0 <= index < len(self._active_workflow.steps):
            self._active_workflow.steps[index].prompt = text_widget.get("1.0", "end-1c")

    def _update_step_delay(self, index: int, value: str):
        if self._active_workflow and 0 <= index < len(self._active_workflow.steps):
            try:
                self._active_workflow.steps[index].delay_after = float(value)
            except ValueError:
                pass  # Ignore invalid input while typing

    def _toggle_step(self, index: int, enabled: bool):
        if self._active_workflow and 0 <= index < len(self._active_workflow.steps):
            self._active_workflow.steps[index].enabled = enabled

    def _move_step(self, from_idx: int, to_idx: int):
        if self._active_workflow:
            self._active_workflow.move_step(from_idx, to_idx)
            self._render_steps()

    def _remove_step(self, index: int):
        if self._active_workflow:
            step_name = self._active_workflow.steps[index].name
            if messagebox.askyesno("Remove Step", f"Remove '{step_name}'?"):
                self._active_workflow.remove_step(index)
                self._render_steps()

    def _add_step(self):
        if not self._active_workflow:
            messagebox.showinfo("Info", "Please select or create a workflow first.")
            return

        num = len(self._active_workflow.steps) + 1
        try:
            delay = float(self._delay_var.get())
        except ValueError:
            delay = 5.0

        new_step = WorkflowStep(
            name=f"Step {num}",
            prompt="Enter your prompt here...",
            delay_after=delay,
        )
        self._active_workflow.add_step(new_step)
        self._render_steps()

        # Scroll to bottom
        self._steps_canvas.update_idletasks()
        self._steps_canvas.yview_moveto(1.0)

    # ═══════════════════════════════════════════════════
    # WORKFLOW CRUD
    # ═══════════════════════════════════════════════════
    def _new_workflow(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("New Workflow")
        dialog.geometry("400x200")
        dialog.configure(bg=COLORS["bg_card"])
        dialog.transient(self.root)
        dialog.grab_set()

        tk.Label(dialog, text="Workflow Name:", font=("Segoe UI", 10),
                 bg=COLORS["bg_card"], fg=COLORS["text"]).pack(padx=20, pady=(20, 4), anchor="w")
        name_var = tk.StringVar()
        name_entry = tk.Entry(dialog, textvariable=name_var, font=("Segoe UI", 11),
                               bg=COLORS["bg_input"], fg=COLORS["text"],
                               insertbackground=COLORS["text"], relief="flat")
        name_entry.pack(fill=tk.X, padx=20, ipady=4)
        name_entry.focus()

        tk.Label(dialog, text="Description:", font=("Segoe UI", 10),
                 bg=COLORS["bg_card"], fg=COLORS["text"]).pack(padx=20, pady=(12, 4), anchor="w")
        desc_var = tk.StringVar()
        desc_entry = tk.Entry(dialog, textvariable=desc_var, font=("Segoe UI", 10),
                               bg=COLORS["bg_input"], fg=COLORS["text"],
                               insertbackground=COLORS["text"], relief="flat")
        desc_entry.pack(fill=tk.X, padx=20, ipady=4)

        def create():
            name = name_var.get().strip()
            if not name:
                return
            wf = Workflow(name=name, description=desc_var.get().strip())
            self._all_workflows[name] = wf
            self._select_workflow(name)
            dialog.destroy()

        tk.Button(dialog, text="Create", font=("Segoe UI", 10, "bold"),
                   bg=COLORS["accent"], fg="#ffffff",
                   activebackground=COLORS["accent_hover"],
                   relief="flat", bd=0, padx=20, pady=6,
                   command=create).pack(pady=16)

        dialog.bind("<Return>", lambda e: create())

    def _save_current_workflow(self):
        if not self._active_workflow:
            return
        try:
            path = self.engine.save_workflow(self._active_workflow, self.WORKFLOW_SAVE_DIR)
            self._log(f"Workflow saved to {path}", "success")
        except Exception as e:
            self._log(f"Failed to save workflow: {e}", "error")

    def _delete_workflow(self):
        if not self._active_workflow:
            return
        name = self._active_workflow.name
        if not messagebox.askyesno("Delete Workflow", f"Delete '{name}'?"):
            return

        del self._all_workflows[name]
        self._active_workflow = None

        # Remove saved file
        safe_name = name.lower().replace(" ", "_").replace("/", "_")
        fpath = os.path.join(self.WORKFLOW_SAVE_DIR, f"workflow_{safe_name}.json")
        if os.path.isfile(fpath):
            os.remove(fpath)

        if self._all_workflows:
            first_name = list(self._all_workflows.keys())[0]
            self._select_workflow(first_name)
        else:
            self._wf_title_label.config(text="No workflows")
            self._wf_desc_label.config(text="")
            self._render_steps()

        self._populate_workflow_list()

    # ═══════════════════════════════════════════════════
    # VARIABLES EDITOR
    # ═══════════════════════════════════════════════════
    def _edit_variables(self):
        if not self._active_workflow:
            return

        dialog = tk.Toplevel(self.root)
        dialog.title("Workflow Variables")
        dialog.geometry("500x400")
        dialog.configure(bg=COLORS["bg_card"])
        dialog.transient(self.root)
        dialog.grab_set()

        tk.Label(dialog, text="Template Variables", font=("Segoe UI", 12, "bold"),
                 bg=COLORS["bg_card"], fg=COLORS["text"]).pack(padx=20, pady=(16, 4), anchor="w")
        tk.Label(dialog, text="Use {variable_name} in your prompts. Set values below:",
                 font=("Segoe UI", 9), bg=COLORS["bg_card"], fg=COLORS["text_dim"]
                 ).pack(padx=20, pady=(0, 12), anchor="w")

        # Common variables
        common_vars = [
            ("project_path", self._project_var.get()),
            ("feature_name", ""),
            ("file_path", ""),
            ("bug_description", ""),
        ]

        entries = {}
        for var_name, default in common_vars:
            current = self._active_workflow.variables.get(var_name, default)
            row = tk.Frame(dialog, bg=COLORS["bg_card"])
            row.pack(fill=tk.X, padx=20, pady=3)
            tk.Label(row, text=f"{{{var_name}}}:", font=("Cascadia Code", 9),
                     bg=COLORS["bg_card"], fg=COLORS["cyan"], width=18, anchor="w"
                     ).pack(side=tk.LEFT)
            var = tk.StringVar(value=current)
            tk.Entry(row, textvariable=var, font=("Segoe UI", 9),
                     bg=COLORS["bg_input"], fg=COLORS["text"],
                     insertbackground=COLORS["text"], relief="flat"
                     ).pack(side=tk.LEFT, fill=tk.X, expand=True, ipady=3)
            entries[var_name] = var

        def save():
            for var_name, var in entries.items():
                val = var.get().strip()
                if val:
                    self._active_workflow.variables[var_name] = val
            dialog.destroy()
            self._log("Variables updated", "info")

        tk.Button(dialog, text="Save Variables", font=("Segoe UI", 10, "bold"),
                   bg=COLORS["accent"], fg="#ffffff",
                   activebackground=COLORS["accent_hover"],
                   relief="flat", bd=0, padx=20, pady=6,
                   command=save).pack(pady=20)

    # ═══════════════════════════════════════════════════
    # EXECUTION
    # ═══════════════════════════════════════════════════
    def _run_workflow(self):
        if not self._active_workflow:
            messagebox.showinfo("Info", "No workflow selected.")
            return

        if self.engine.is_running:
            messagebox.showinfo("Info", "A workflow is already running.")
            return

        # Update bridge settings
        self.bridge.project_path = Path(self._project_var.get())
        self.bridge.editor = self._editor_var.get()
        self.bridge.mode = self._mode_var.get()

        # Auto-set project_path variable
        self._active_workflow.variables.setdefault("project_path", self._project_var.get())

        self._log(f"▶ Starting workflow: {self._active_workflow.name}", "info")
        self._log(f"  Editor: {self.bridge.editor_display_name}  |  Mode: {self.bridge.mode}", "dim")

        # Wire up the correct send function based on mode
        if self.bridge.mode == "auto_interact":
            self.engine.send_and_wait_fn = self.bridge.send_and_wait
            self.engine.send_prompt_fn = None
            self._log("  🤖 Auto-Interact: will type into editor + wait for AI completion", "info")
        else:
            self.engine.send_and_wait_fn = None
            self.engine.send_prompt_fn = self.bridge.send_prompt

        # Update button states
        self._run_btn.config(state="disabled")
        self._pause_btn.config(state="normal")
        self._stop_btn.config(state="normal")
        self._status_var.set("Running...")

        # Reset step visuals & Apply Global Cooldown
        global_delay = None
        if self._step_cooldown_var.get().strip():
            try:
                global_delay = float(self._step_cooldown_var.get().strip())
            except ValueError:
                pass

        for step in self._active_workflow.steps:
            step.status = "pending"
            if global_delay is not None:
                step.delay_after = global_delay
        
        self._render_steps()

        # Update loop settings
        self.engine.loop_mode = self._loop_var.get()
        try:
            mins = float(self._loop_interval_var.get())
            self.engine.loop_interval = max(0.1, mins * 60.0)
        except ValueError:
            self.engine.loop_interval = 120.0

        # Start!
        self.engine.start(self._active_workflow)

    def _pause_resume(self):
        if self.engine.is_paused:
            self.engine.resume()
            self._pause_btn.config(text="⏸ Pause")
            self._status_var.set("Running...")
            self._log("▶ Resumed", "info")
        else:
            self.engine.pause()
            self._pause_btn.config(text="▶ Resume")
            self._status_var.set("Paused")
            self._log("⏸ Paused", "warning")

    def _stop_workflow(self):
        self.engine.cancel()
        self.bridge.cancel_wait()  # also cancel any active wait-for-completion
        self._loop_var.set(False)  # stop loop on manual stop
        self._log("⏹ Cancelling...", "warning")

    # ═══════════════════════════════════════════════════
    # ENGINE CALLBACKS (called from background thread)
    # ═══════════════════════════════════════════════════
    def _on_step_start(self, index: int, step: WorkflowStep):
        self.root.after(0, self._ui_step_start, index, step.name)

    def _ui_step_start(self, index: int, name: str):
        self._log(f"⏳ Step {index + 1}: {name}", "step")
        self._render_steps()

    def _on_step_complete(self, index: int, step: WorkflowStep, result: str):
        self.root.after(0, self._ui_step_complete, index, step.name, result)

    def _ui_step_complete(self, index: int, name: str, result: str):
        self._log(f"✅ Step {index + 1} complete: {name}", "success")
        if result:
            # Show first 200 chars of result
            preview = result[:200].replace("\n", " ")
            self._log(f"   → {preview}", "dim")
        self._render_steps()

    def _on_step_error(self, index: int, step: WorkflowStep, error: str):
        self.root.after(0, self._ui_step_error, index, step.name, error)

    def _ui_step_error(self, index: int, name: str, error: str):
        self._log(f"❌ Step {index + 1} failed: {name} — {error}", "error")
        self._render_steps()

    def _on_workflow_done(self, workflow: Workflow, status: str):
        self.root.after(0, self._ui_workflow_done, workflow.name, status)

    def _ui_workflow_done(self, name: str, status: str):
        if status == "completed":
            self._log(f"🎉 Workflow '{name}' completed successfully!", "success")
        elif status == "cancelled":
            self._log(f"⏹ Workflow '{name}' was cancelled.", "warning")
        elif status == "looping":
            self._log(f"🔄 Workflow '{name}' run complete. Looping...", "info")
            return  # don't reset buttons yet
        else:
            self._log(f"⚠ Workflow '{name}' finished with status: {status}", "error")

        self._run_btn.config(state="normal")
        self._pause_btn.config(state="disabled", text="⏸ Pause")
        self._stop_btn.config(state="disabled")
        self._progress_var.set(0)
        self._status_var.set("Ready")
        self._ai_status_var.set("")
        self._render_steps()

    def _on_progress(self, current: int, total: int, percent: float):
        self.root.after(0, self._progress_var.set, percent)

    def _on_bridge_status(self, status: str, detail: str):
        """Called from bridge (background thread) when AI status changes"""
        self.root.after(0, self._ui_bridge_status, status, detail)

    def _ui_bridge_status(self, status: str, detail: str):
        """Update the live AI status indicator"""
        status_colors = {
            "typing": COLORS["yellow"],
            "waiting": COLORS["cyan"],
            "cooldown": COLORS["green"],
            "done": COLORS["green"],
        }
        color = status_colors.get(status, COLORS["text_dim"])
        self._ai_status_label.config(fg=color)
        self._ai_status_var.set(detail)
        self._status_var.set(detail)

    def _on_loop_wait(self, countdown: float):
        self.root.after(0, self._ui_loop_wait, countdown)

    def _ui_loop_wait(self, countdown: float):
        detail = f"🔄 Next run in: {int(countdown)}s"
        self._ai_status_label.config(fg=COLORS["yellow"])
        self._ai_status_var.set(detail)
        self._status_var.set(detail)

    # ═══════════════════════════════════════════════════
    # LOG
    # ═══════════════════════════════════════════════════
    def _log(self, message: str, tag: str = ""):
        timestamp = datetime.now().strftime("%H:%M:%S")
        self._log_text.insert("end", f"[{timestamp}] ", "timestamp")
        self._log_text.insert("end", f"{message}\n", tag if tag else "")
        self._log_text.see("end")

    def _clear_log(self):
        self._log_text.delete("1.0", "end")

    # ═══════════════════════════════════════════════════
    # SETTINGS
    # ═══════════════════════════════════════════════════
    def _show_settings(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("Settings")
        dialog.geometry("460x320")
        dialog.configure(bg=COLORS["bg_card"])
        dialog.transient(self.root)
        dialog.grab_set()

        tk.Label(dialog, text="⚙ Settings", font=("Segoe UI", 14, "bold"),
                 bg=COLORS["bg_card"], fg=COLORS["text"]).pack(padx=20, pady=(16, 12), anchor="w")

        # Import workflow from file
        import_frame = tk.Frame(dialog, bg=COLORS["bg_card"])
        import_frame.pack(fill=tk.X, padx=20, pady=4)
        tk.Label(import_frame, text="Import Workflow:", font=("Segoe UI", 10),
                 bg=COLORS["bg_card"], fg=COLORS["text"]).pack(side=tk.LEFT)
        tk.Button(import_frame, text="Import JSON", font=("Segoe UI", 9),
                   bg=COLORS["bg_input"], fg=COLORS["text_dim"],
                   activebackground=COLORS["bg_hover"],
                   relief="flat", bd=0, padx=10, pady=3,
                   command=lambda: self._import_workflow(dialog)
                   ).pack(side=tk.RIGHT)

        # Export workflow
        export_frame = tk.Frame(dialog, bg=COLORS["bg_card"])
        export_frame.pack(fill=tk.X, padx=20, pady=4)
        tk.Label(export_frame, text="Export Current:", font=("Segoe UI", 10),
                 bg=COLORS["bg_card"], fg=COLORS["text"]).pack(side=tk.LEFT)
        tk.Button(export_frame, text="Export JSON", font=("Segoe UI", 9),
                   bg=COLORS["bg_input"], fg=COLORS["text_dim"],
                   activebackground=COLORS["bg_hover"],
                   relief="flat", bd=0, padx=10, pady=3,
                   command=lambda: self._export_workflow(dialog)
                   ).pack(side=tk.RIGHT)

        # Auto-focus toggle
        focus_frame = tk.Frame(dialog, bg=COLORS["bg_card"])
        focus_frame.pack(fill=tk.X, padx=20, pady=12)
        auto_focus_var = tk.BooleanVar(value=self.bridge._auto_focus)
        tk.Checkbutton(
            focus_frame, text="Auto-focus editor window after sending prompt",
            variable=auto_focus_var, bg=COLORS["bg_card"], fg=COLORS["text"],
            selectcolor=COLORS["bg_dark"], activebackground=COLORS["bg_card"],
            font=("Segoe UI", 10),
            command=lambda: setattr(self.bridge, "_auto_focus", auto_focus_var.get()),
        ).pack(anchor="w")

        # Workflow save directory
        dir_frame = tk.Frame(dialog, bg=COLORS["bg_card"])
        dir_frame.pack(fill=tk.X, padx=20, pady=4)
        tk.Label(dir_frame, text="Save directory:", font=("Segoe UI", 9),
                 bg=COLORS["bg_card"], fg=COLORS["text_dim"]).pack(anchor="w")
        tk.Label(dir_frame, text=self.WORKFLOW_SAVE_DIR, font=("Cascadia Code", 8),
                 bg=COLORS["bg_card"], fg=COLORS["text_muted"]).pack(anchor="w")

        tk.Button(dialog, text="Close", font=("Segoe UI", 10),
                   bg=COLORS["bg_input"], fg=COLORS["text"],
                   activebackground=COLORS["bg_hover"],
                   relief="flat", bd=0, padx=20, pady=6,
                   command=dialog.destroy).pack(pady=16)

    def _import_workflow(self, parent):
        path = filedialog.askopenfilename(
            parent=parent, filetypes=[("JSON files", "*.json")],
            title="Import Workflow",
        )
        if path:
            try:
                wf = self.engine.load_workflow(path)
                self._all_workflows[wf.name] = wf
                self._select_workflow(wf.name)
                self._log(f"Imported workflow: {wf.name}", "success")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to import: {e}")

    def _export_workflow(self, parent):
        if not self._active_workflow:
            return
        path = filedialog.asksaveasfilename(
            parent=parent,
            filetypes=[("JSON files", "*.json")],
            defaultextension=".json",
            initialfile=f"workflow_{self._active_workflow.name.lower().replace(' ', '_')}.json",
            title="Export Workflow",
        )
        if path:
            try:
                with open(path, "w", encoding="utf-8") as f:
                    json.dump(self._active_workflow.to_dict(), f, indent=2, ensure_ascii=False)
                self._log(f"Exported workflow to {path}", "success")
            except Exception as e:
                messagebox.showerror("Error", f"Failed to export: {e}")

    # ═══════════════════════════════════════════════════
    # MISC
    # ═══════════════════════════════════════════════════
    def _browse_project(self):
        path = filedialog.askdirectory(initialdir=self._project_var.get())
        if path:
            self._project_var.set(path)
            self.bridge.project_path = Path(path)

    def _on_editor_change(self, event=None):
        editor = self._editor_var.get()
        self.bridge.editor = editor
        display = self.bridge.editor_display_name
        icon = EditorBridge.EDITORS.get(editor, {}).get("icon", "")
        self._editor_status.config(text=f"{icon} {display}")
        self._log(f"Editor switched to {display}", "info")

    def _on_mode_change(self, event=None):
        self.bridge.mode = self._mode_var.get()
        self._log(f"Send mode: {self._mode_var.get()}", "info")

    def _load_project_path(self):
        """Try to load project path from .env"""
        for env_name in [".env", ".env.example"]:
            env_file = Path(os.path.dirname(os.path.abspath(__file__))) / env_name
            if env_file.exists():
                try:
                    with open(env_file) as f:
                        for line in f:
                            line = line.strip()
                            if line.startswith("PROJECT_PATH="):
                                self._project_var.set(line.split("=", 1)[1])
                                return
                except Exception:
                    pass


def main():
    root = tk.Tk()

    # Set icon if available
    try:
        root.iconbitmap(default="")
    except Exception:
        pass

    app = AutoPromptGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
