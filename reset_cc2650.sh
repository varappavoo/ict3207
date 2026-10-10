#!/bin/bash

# ==========================================================
# CC2650 SensorTag Full System Reset using XDS110
# Programmer: LAUNCHXL-CC1352R1
# Interface: JTAG
# ==========================================================

echo "Searching for XDS110 devices..."

SERIALS=()

while IFS= read -r serial; do
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

# ----------------------------------------------------------
# Select XDS110 device
# ----------------------------------------------------------

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
echo "=========================================="
echo "Selected XDS110 : $SERIAL"
echo "JTAG Speed      : 100 kHz"
echo "Operation       : System Hardware Reset"
echo "=========================================="
echo

# ----------------------------------------------------------
# Execute OpenOCD
# ----------------------------------------------------------

openocd \
    -f /usr/share/openocd/scripts/interface/xds110.cfg \
    -c "adapter serial $SERIAL" \
    -c "transport select jtag" \
    -c "adapter speed 1000" \
    -f /usr/share/openocd/scripts/target/ti_cc26x0.cfg \
    -c "reset_config srst_only srst_nogate" \
    -c "init" \
    -c "reset run" \
    -c "shutdown"

STATUS=$?

echo

if [ $STATUS -eq 0 ]; then
    echo "======================================"
    echo " Reset command completed successfully."
    echo " XDS110: $SERIAL"
    echo "======================================"
else
    echo "======================================"
    echo " Reset FAILED."
    echo " XDS110: $SERIAL"
    echo "======================================"
fi

exit $STATUS
