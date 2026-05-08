#!/usr/bin/env python3
"""
Generic AI client — wraps the `claude` CLI for use in periodic job scripts.
Drop-in replacement for opencode_client.py.
"""
import subprocess
import time
from datetime import datetime


class AIClient:
    def __init__(self, default_model="claude-sonnet-4-6"):
        self.default_model = default_model
        self._sessions = {}  # session_id -> {"output": str, "done": bool}

    def create_session(self, title: str) -> str:
        session_id = f"{title}-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        self._sessions[session_id] = {"output": "", "done": False}
        return session_id

    def send_message(self, session_id: str, message: str, model_id: str = None, **kwargs) -> dict | None:
        model = model_id or self.default_model
        cmd = [
            "claude", "-p", message,
            "--model", model,
            "--allowedTools", "Bash,Read,Edit,Write",
            "--dangerously-skip-permissions",
        ]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            output = result.stdout
            if result.returncode != 0:
                print(f"claude CLI error (exit {result.returncode}): {result.stderr[:300]}")
                return None
            if session_id in self._sessions:
                self._sessions[session_id]["output"] = output
                self._sessions[session_id]["done"] = True
            print(output)
            return {"status": "ok", "session_id": session_id}
        except FileNotFoundError:
            print("Error: `claude` CLI not found. Make sure Claude Code is installed and in PATH.")
            return None
        except Exception as e:
            print(f"Error running claude CLI: {e}")
            return None

    def wait_for_session_complete(self, session_id: str, **kwargs) -> bool:
        # subprocess.run is synchronous — already done by the time send_message returns
        return True

    def delete_session(self, session_id: str) -> bool:
        self._sessions.pop(session_id, None)
        return True
