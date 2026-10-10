#!/bin/bash

BAUD=115200
SERIAL_DIR="/dev/serial/by-id"

# Get only devices ending with if00
DEVICES=("$SERIAL_DIR"/*if00)

if [ ! -e "${DEVICES[0]}" ]; then
    echo "No serial devices ending with if00 found."
    exit 1
fi

echo "Available serial devices:"
echo

for i in "${!DEVICES[@]}"; do
    ID=$(basename "${DEVICES[$i]}")
    TARGET=$(readlink -f "${DEVICES[$i]}")

    echo "  $((i+1))) $ID"
    echo "      -> $TARGET"
done

echo

while true; do
    read -rp "Select device [1-${#DEVICES[@]}]: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] &&
       (( choice >= 1 && choice <= ${#DEVICES[@]} )); then
        break
    fi

    echo "Invalid selection."
done

DEVICE="${DEVICES[$((choice-1))]}"
TARGET=$(readlink -f "$DEVICE")

echo
echo "Selected:"
echo "  ID:     $(basename "$DEVICE")"
echo "  Device: $TARGET"
echo "  Baud:   $BAUD"
echo

serialdump -b"$BAUD" "$DEVICE"
