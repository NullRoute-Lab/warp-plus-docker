#!/bin/bash

# Initial arguments passed to warp-plus
INIT_ARGS=("$@")
PID_FILE="/tmp/warp-plus.pid"

check_proxy() {
    # Lightweight connectivity check using Google's 204 test page
    curl --socks5 127.0.0.1:8086 -s -o /dev/null -w "%{http_code}" --max-time 5 http://www.gstatic.com/generate_204 | grep -q "^204$"
    return $?
}

start_warp() {
    echo "$(date) - Starting warp-plus with args: ${INIT_ARGS[*]}"
    ./warp-plus "${INIT_ARGS[@]}" &
    echo $! > "$PID_FILE"
    echo "$(date) - warp-plus PID is $(cat "$PID_FILE")"
}

stop_warp() {
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "$(date) - Stopping warp-plus (pid $pid)..."
            kill "$pid"
            wait "$pid" 2>/dev/null
        else
            echo "$(date) - warp-plus process $pid not running, cleaning up PID file."
        fi
        rm -f "$PID_FILE"
    else
        echo "$(date) - No PID file, nothing to stop."
    fi
}

restarting=0

restart_warp() {
    if [ "$restarting" -eq 1 ]; then
        echo "$(date) - Restart already in progress, skipping."
        return
    fi

    restarting=1
    echo "$(date) - Restarting warp-plus..."

    stop_warp
    start_warp

    restarting=0
}

# Initial start
start_warp

# Process monitor: restarts if process is dead
(
    while true; do
        if [ ! -f "$PID_FILE" ]; then
            echo "$(date) - PID file missing, restarting warp-plus..."
            restart_warp
        else
            pid=$(cat "$PID_FILE")
            if ! kill -0 "$pid" 2>/dev/null; then
                echo "$(date) - warp-plus process $pid not found or dead, restarting..."
                restart_warp
            fi
        fi
        sleep 1
    done
) &

# Proxy check: starts after 2 minutes, then runs every 60s
(
    echo "$(date) - Waiting 2 minutes before starting proxy checks..."
    sleep 120

    while true; do
        if ! check_proxy; then
            echo "$(date) - Proxy check failed, restarting warp-plus and waiting 2 minutes..."
            restart_warp
            sleep 120
        else
            echo "$(date) - Proxy check succeeded."
        fi
        sleep 60
    done
) &

wait

