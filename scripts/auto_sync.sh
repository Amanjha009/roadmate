#!/usr/bin/env bash
# RoadMate Auto-Git-Sync Manager
# Usage:
#   ./scripts/auto_sync.sh start           # Start background sync daemon
#   ./scripts/auto_sync.sh stop            # Stop sync daemon
#   ./scripts/auto_sync.sh status          # Check daemon status & view recent syncs
#   ./scripts/auto_sync.sh logs            # Tail sync logs
#   ./scripts/auto_sync.sh install-service # Enable systemd auto-start on boot

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PID_FILE="$REPO_DIR/.git/auto_sync.pid"
LOG_FILE="$REPO_DIR/.git/auto_sync.log"
PYTHON_SCRIPT="$SCRIPT_DIR/auto_git_sync.py"
SERVICE_NAME="roadmate-autosync.service"
USER_SYSTEMD_DIR="$HOME/.config/systemd/user"

case "$1" in
  start)
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "⚡ RoadMate Auto-Sync is already running (PID $(cat "$PID_FILE"))."
      exit 0
    fi
    echo "🚀 Starting RoadMate Auto-Git-Sync daemon in background..."
    nohup python3 "$PYTHON_SCRIPT" >> "$LOG_FILE" 2>&1 &
    sleep 1
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "✅ RoadMate Auto-Sync is now running (PID $(cat "$PID_FILE"))."
      echo "Any changes saved to files will automatically commit and push to GitHub within ~6 seconds."
    else
      echo "❌ Failed to start auto-sync daemon. Check $LOG_FILE"
      exit 1
    fi
    ;;

  stop)
    if [ -f "$PID_FILE" ]; then
      PID=$(cat "$PID_FILE")
      if kill -0 "$PID" 2>/dev/null; then
        echo "🛑 Stopping RoadMate Auto-Sync daemon (PID $PID)..."
        kill "$PID"
        sleep 1
      fi
      rm -f "$PID_FILE"
      echo "✅ Auto-Sync daemon stopped."
    else
      echo "ℹ️ Auto-Sync daemon is not running."
    fi
    ;;

  status)
    echo "============================================="
    echo "     RoadMate GitHub Auto-Sync Status        "
    echo "============================================="
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
      echo "Status: 🟢 RUNNING (PID $(cat "$PID_FILE"))"
    elif systemctl --user is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
      echo "Status: 🟢 RUNNING via systemd user service"
    else
      echo "Status: 🔴 STOPPED"
    fi
    echo "Repository: $REPO_DIR"
    echo "Branch:     $(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD)"
    echo "Remote:     $(git -C "$REPO_DIR" config --get remote.origin.url)"
    echo ""
    if [ -f "$LOG_FILE" ]; then
      echo "--- Recent Sync Events ---"
      tail -n 8 "$LOG_FILE"
    fi
    echo "============================================="
    ;;

  logs)
    if [ -f "$LOG_FILE" ]; then
      tail -f -n 20 "$LOG_FILE"
    else
      echo "Log file $LOG_FILE not found yet."
    fi
    ;;

  install-service)
    echo "⚙️ Installing systemd user service to run automatically on system boot..."
    mkdir -p "$USER_SYSTEMD_DIR"
    cat <<EOF > "$USER_SYSTEMD_DIR/$SERVICE_NAME"
[Unit]
Description=RoadMate GitHub Auto-Sync Daemon
After=network.target

[Service]
Type=simple
WorkingDirectory=$REPO_DIR
ExecStart=/usr/bin/python3 $PYTHON_SCRIPT
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable "$SERVICE_NAME"
    systemctl --user restart "$SERVICE_NAME"
    echo "✅ systemd service '$SERVICE_NAME' installed and started!"
    echo "Check status anytime with: systemctl --user status $SERVICE_NAME"
    ;;

  *)
    echo "RoadMate Auto-Git-Sync Manager"
    echo "Usage: $0 {start|stop|status|logs|install-service}"
    exit 1
    ;;
esac
