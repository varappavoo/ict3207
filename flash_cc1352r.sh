
#!/usr/bin/env bash
# Flash, verify and reset LPSTK-CC1352R1 using an XDS110 debugger.
# Usage: ./flash_cc1352r.sh <firmware.elf|firmware.simplelink>

set -Eeuo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <firmware-file>"
    exit 1
fi

FIRMWARE="$(realpath "$1")"

if [[ ! -f "$FIRMWARE" ]]; then
    echo "ERROR: Firmware not found: $FIRMWARE"
    exit 1
fi

IFACE_CFG="/usr/share/openocd/scripts/interface/xds110.cfg"
TARGET_CFG="/usr/share/openocd/scripts/target/ti_cc13x2.cfg"

if [[ ! -f "$IFACE_CFG" || ! -f "$TARGET_CFG" ]]; then
    echo "ERROR: OpenOCD configuration files not found."
    exit 1
fi

command -v openocd >/dev/null || {
    echo "ERROR: OpenOCD is not installed."
    exit 1
}

command -v lsusb >/dev/null || {
    echo "ERROR: lsusb is not installed."
    exit 1
}

echo "Searching for XDS110 devices..."

SERIALS=()

# Enumerate XDS110 devices by USB VID:PID (0451:bef3).
# Read serials using sysfs rather than parsing lsusb -v output.
for device in /sys/bus/usb/devices/*; do
    [[ -f "$device/idVendor" &&
       -f "$device/idProduct" ]] || continue

    vendor=$(<"$device/idVendor")
    product=$(<"$device/idProduct")

    if [[ "$vendor" == "0451" && "$product" == "bef3" ]]; then
        if [[ -r "$device/serial" ]]; then
            serial=$(<"$device/serial")
            [[ -n "$serial" ]] && SERIALS+=("$serial")
        fi
    fi
done

if [[ ${#SERIALS[@]} -eq 0 ]]; then
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

# Allow selection using an environment variable.
SERIAL="${XDS110_SERIAL:-}"

if [[ -z "$SERIAL" ]]; then
    while true; do
        read -rp "Select device [1-${#SERIALS[@]}]: " choice

        if [[ "$choice" =~ ^[0-9]+$ ]] &&
           (( 10#$choice >= 1 &&
              10#$choice <= ${#SERIALS[@]} )); then
            SERIAL="${SERIALS[$((10#$choice-1))]}"
            break
        fi

        echo "Invalid selection."
    done
else
    found=false
    for device_serial in "${SERIALS[@]}"; do
        if [[ "$SERIAL" == "$device_serial" ]]; then
            found=true
            break
        fi
    done

    if [[ "$found" != true ]]; then
        echo "ERROR: XDS110 serial $SERIAL not found."
        exit 1
    fi
fi

echo
echo "======================================"
echo " Target   : LPSTK-CC1352R1"
echo " XDS110   : $SERIAL"
echo " Firmware : $FIRMWARE"
echo " Speed    : 100 kHz"
echo "======================================"
echo

# Flash, verify, halt, and reset.
if openocd \
    -f "$IFACE_CFG" \
    -c "adapter serial $SERIAL" \
    -c "transport select jtag" \
    -c "adapter speed 1000" \
    -f "$TARGET_CFG" \
    -c "init" \
    -c "reset halt" \
    -c "program \"$FIRMWARE\" verify" \
    -c "reset halt" \
    -c "reset run" \
    -c "shutdown"
then
    echo
    echo "======================================"
    echo " Flash completed successfully."
    echo " Target : LPSTK-CC1352R1"
    echo " XDS110 : $SERIAL"
    echo "======================================"
else
    echo
    echo "======================================"
    echo " Flashing FAILED."
    echo " Target : LPSTK-CC1352R1"
    echo " XDS110 : $SERIAL"
    echo "======================================"
    exit 1
fi
