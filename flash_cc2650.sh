#!/bin/bash
# Usage:
# ./flash_cc2650.sh <full (absolute) path of firmware-file, e.g. /home/ict3207/contiki-ng/examples/platform-specific/cc26x0-cc13x0/base-demo/build/cc26x0-cc13x0/sensortag/cc2650/base-demo.cc26x0-cc13x0>
# usage example:
# ./flash_cc2650.sh /home/ict3207/contiki-ng/examples/hello-world/build/cc26x0-cc13x0/sensortag/cc2650/hello-world.cc26x0-cc13x0

if [ $# -ne 1 ]; then
    echo "Usage: $0 <full (absolute) path of firmware-file, e.g. '/home/ict3207/contiki-ng/examples/platform-specific/cc26x0-cc13x0/base-demo/build/cc26x0-cc13x0/sensortag/cc2650/base-demo.cc26x0-cc13x0'>"
    exit 1
fi

FIRMWARE="$(realpath "$1")"

if [ ! -f "$FIRMWARE" ]; then
    echo "ERROR: Firmware not found: $FIRMWARE"
    exit 1
fi

echo "Searching for XDS110 devices..."

SERIALS=()

while IFS= read -r serial; do
    # Remove whitespace and possible CR characters
    serial=$(echo "$serial" | tr -d '[:space:]')

    if [ -n "$serial" ]; then
        SERIALS+=("$serial")
    fi
done < <(
    lsusb -v 2>/dev/null |
    awk '
        /Texas Instruments/ {ti=1}
        ti && /iSerial/ {
            print $3
            ti=0
        }
    '
)

if [ ${#SERIALS[@]} -eq 0 ]; then
    echo "ERROR: No XDS110 devices found."
    exit 1
fi

echo
echo "Connected XDS110 devices:"
echo

for i in "${!SERIALS[@]}"; do
    echo "  $((i+1))) ${SERIALS[$i]}"
done

echo

while true; do
    read -rp "Select device [1-${#SERIALS[@]}]: " choice

    if [[ "$choice" =~ ^[0-9]+$ ]] &&
       (( choice >= 1 && choice <= ${#SERIALS[@]} )); then
        break
    fi

    echo "Invalid selection."
done

SERIAL="${SERIALS[$((choice-1))]}"

echo
echo "Selected XDS110: [$SERIAL]"
echo "Firmware:        [$FIRMWARE]"
echo

# Debug: show exactly what is stored in SERIAL
printf 'Serial bytes: '
printf '%s' "$SERIAL" | od -An -tx1
echo

openocd \
    -f /usr/share/openocd/scripts/interface/xds110.cfg \
    -c "adapter serial $SERIAL" \
    -c "transport select jtag" \
    -c "adapter speed 100" \
    -f /usr/share/openocd/scripts/target/ti_cc26x0.cfg \
    -c "init" \
    -c "reset halt" \
    -c "program $FIRMWARE verify" \
    -c "reset halt" \
    -c "reset run" \
    -c "shutdown"

STATUS=$?

echo

if [ $STATUS -eq 0 ]; then
    echo "======================================"
    echo " Flash completed successfully."
    echo " XDS110: $SERIAL"
    echo "======================================"
else
    echo "======================================"
    echo " Flashing FAILED."
    echo " XDS110: $SERIAL"
    echo "======================================"
fi

exit $STATUS
