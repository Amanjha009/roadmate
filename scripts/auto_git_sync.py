#!/usr/bin/env python3
"""
RoadMate Auto-Sync Daemon
Monitors the workspace for file changes, debounces rapid edits,
and automatically commits and pushes changes to GitHub.
"""

import os
import sys
import time
import signal
import subprocess
from datetime import datetime
from pathlib import Path

REPO_DIR = Path(__file__).resolve().parent.parent
LOG_FILE = REPO_DIR / ".git" / "auto_sync.log"
PID_FILE = REPO_DIR / ".git" / "auto_sync.pid"

CHECK_INTERVAL_SEC = 5.0
DEBOUNCE_SEC = 6.0
MAX_DEBOUNCE_WAIT_SEC = 30.0

running = True


def log(msg: str):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    formatted = f"[{timestamp}] [Auto-Sync] {msg}"
    print(formatted, flush=True)
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(formatted + "\n")
    except Exception:
        pass


def handle_sigterm(signum, frame):
    global running
    log("Termination signal received. Shutting down auto-sync daemon...")
    running = False


def get_git_status():
    """Returns list of changed files from git status --porcelain."""
    try:
        res = subprocess.run(
            ["git", "status", "--porcelain"],
            cwd=str(REPO_DIR),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=10,
        )
        if res.returncode != 0:
            return []
        lines = [line.strip() for line in res.stdout.splitlines() if line.strip()]
        return lines
    except Exception as e:
        log(f"Error checking git status: {e}")
        return []


def perform_sync(status_lines):
    """Stages, commits, and pushes changes to origin main."""
    try:
        # Extract changed file paths for a descriptive commit message
        files = []
        for line in status_lines:
            parts = line.split(maxsplit=1)
            if len(parts) == 2:
                files.append(parts[1])

        file_summary = ", ".join(files[:3])
        if len(files) > 3:
            file_summary += f" and {len(files) - 3} more files"

        commit_msg = f"auto-sync: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ({file_summary})"

        log(f"Changes detected in {len(files)} file(s): {file_summary}")
        log("Running git add -A...")
        add_res = subprocess.run(
            ["git", "add", "-A"],
            cwd=str(REPO_DIR),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=30,
        )
        if add_res.returncode != 0:
            log(f"git add failed: {add_res.stderr.strip()}")
            return False

        # Double check if anything was staged
        diff_res = subprocess.run(
            ["git", "diff", "--cached", "--quiet"],
            cwd=str(REPO_DIR),
            timeout=10,
        )
        if diff_res.returncode == 0:
            log("No staged changes to commit.")
            return True

        log(f"Creating commit: '{commit_msg}'")
        commit_res = subprocess.run(
            ["git", "commit", "-m", commit_msg],
            cwd=str(REPO_DIR),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=30,
        )
        if commit_res.returncode != 0:
            log(f"git commit failed: {commit_res.stderr.strip()}")
            return False

        log("Pushing to GitHub (origin main)...")
        push_res = subprocess.run(
            ["git", "push", "origin", "main"],
            cwd=str(REPO_DIR),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=60,
        )
        if push_res.returncode == 0:
            log("✅ Successfully pushed changes to GitHub!")
            return True
        else:
            log(f"⚠️ Push encountered an issue: {push_res.stderr.strip()} (will retry next change)")
            return False

    except subprocess.TimeoutExpired:
        log("⚠️ Git command timed out. Will retry on next check.")
        return False
    except Exception as e:
        log(f"⚠️ Unexpected sync error: {e}")
        return False


def main():
    signal.signal(signal.SIGTERM, handle_sigterm)
    signal.signal(signal.SIGINT, handle_sigterm)

    # Write PID file
    PID_FILE.write_text(str(os.getpid()), encoding="utf-8")
    log(f"🚀 RoadMate Git Auto-Sync daemon started (PID {os.getpid()})")
    log(f"Monitoring: {REPO_DIR}")

    last_changes = None
    change_first_seen = None
    last_change_time = None

    try:
        while running:
            status = get_git_status()
            now = time.time()

            if status:
                if last_changes is None or set(status) != set(last_changes):
                    last_changes = status
                    last_change_time = now
                    if change_first_seen is None:
                        change_first_seen = now
                    log(f"Active edits detected ({len(status)} files modified). Debouncing...")

                # Debounce logic: wait until edits settle for DEBOUNCE_SEC or max wait exceeded
                idle_time = now - last_change_time
                total_wait = now - change_first_seen

                if idle_time >= DEBOUNCE_SEC or total_wait >= MAX_DEBOUNCE_WAIT_SEC:
                    perform_sync(status)
                    last_changes = None
                    change_first_seen = None
                    last_change_time = None
            else:
                last_changes = None
                change_first_seen = None
                last_change_time = None

            time.sleep(CHECK_INTERVAL_SEC)

    finally:
        if PID_FILE.exists():
            try:
                PID_FILE.unlink()
            except Exception:
                pass
        log("Auto-sync daemon stopped.")


if __name__ == "__main__":
    main()
