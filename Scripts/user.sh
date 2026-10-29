#!/usr/bin/env bash

CMD="su - user"

if command -v gnome-terminal &>/dev/null; then
    exec gnome-terminal -- bash -c "$CMD"
elif command -v ptyxis &>/dev/null; then
    exec ptyxis -- bash -c "$CMD"
elif command -v konsole &>/dev/null; then
    exec konsole -e bash -c "$CMD"
elif command -v xfce4-terminal &>/dev/null; then
    exec xfce4-terminal -e "bash -c '$CMD'"
elif command -v xterm &>/dev/null; then
    exec xterm -e bash -c "$CMD"
else
    echo "No supported GUI terminal emulator found." >&2
    exit 1
fi
