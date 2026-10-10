#!/usr/bin/env bash

# ============================================================
# CONTIKI-NG COMPLETE INSTALLATION
#
# Ubuntu 24.04
#
# Hardware:
#   TI CC2650 SensorTag
#   TI XDS110
#
# Software:
#   Contiki-NG
#   ARM GCC
#   OpenOCD
#   Cooja
#   Java
#   Gradle Wrapper
#
# Contiki target:
#   TARGET=simplelink
#   BOARD=sensortag/cc2650
#
# ============================================================

set -e

CONTIKI_DIR="$HOME/contiki-ng"

echo
echo "============================================================"
echo " Contiki-NG Complete Development Environment"
echo "============================================================"
echo
echo "Ubuntu 24.04"
echo "CC2650 SensorTag"
echo "XDS110"
echo "OpenOCD"
echo "Cooja"
echo

# ============================================================
# 1. OPERATING SYSTEM
# ============================================================

echo "[1/16] Checking operating system..."

if [ ! -f /etc/os-release ]; then
    echo "ERROR: Cannot determine operating system."
    exit 1
fi

source /etc/os-release

echo "Detected:"
echo "  $PRETTY_NAME"

if [ "$ID" != "ubuntu" ]; then
    echo
    echo "WARNING: This script was designed for Ubuntu."
fi

# ============================================================
# 2. UPDATE SYSTEM
# ============================================================

echo
echo "[2/16] Updating Ubuntu..."

sudo apt update

# ============================================================
# 3. INSTALL GENERAL DEVELOPMENT PACKAGES
# ============================================================

echo
echo "[3/16] Installing development packages..."

sudo apt install -y \
    build-essential \
    git \
    git-lfs \
    curl \
    wget \
    python3 \
    python3-pip \
    python3-serial \
    srecord \
    cmake \
    ninja-build \
    pkg-config \
    libusb-1.0-0-dev \
    libftdi1-dev \
    libhidapi-dev \
    libjaylink-dev \
    libtool \
    autoconf \
    automake \
    texinfo \
    usbutils \
    screen \
    unzip \
    zip

# ============================================================
# 4. INSTALL ARM GCC
# ============================================================

echo
echo "[4/16] Installing ARM GCC toolchain..."

sudo apt install -y \
    gcc-arm-none-eabi \
    binutils-arm-none-eabi \
    libnewlib-arm-none-eabi

echo
echo "ARM GCC:"
arm-none-eabi-gcc --version | head -n 1

echo
echo "ARM GDB:"
arm-none-eabi-gdb --version | head -n 1

# ============================================================
# 5. INSTALL JAVA
# ============================================================

echo
echo "[5/16] Installing Java..."

sudo apt install -y \
    openjdk-21-jdk

echo
echo "Java:"
java -version

# ============================================================
# 6. INSTALL GUI / X11 / WAYLAND SUPPORT
# ============================================================

echo
echo "[6/16] Installing Cooja GUI dependencies..."

sudo apt install -y \
    xwayland \
    libxext6 \
    libxrender1 \
    libxtst6 \
    libxi6 \
    libgtk-3-0 \
    libx11-6 \
    libx11-xcb1 \
    libxcb1 \
    libxcb-xinerama0 \
    libxcb-render0 \
    libxcb-shm0 \
    libgl1

# ============================================================
# 7. INSTALL OPENOCD
# ============================================================

echo
echo "[7/16] Installing OpenOCD..."

sudo apt install -y openocd

echo
echo "OpenOCD:"
openocd --version 2>&1 | head -n 1

OPENOCD_BIN="$(command -v openocd)"

if [ -z "$OPENOCD_BIN" ]; then
    echo
    echo "ERROR: OpenOCD was not installed."
    exit 1
fi

echo
echo "OpenOCD executable:"
echo "  $OPENOCD_BIN"

# ============================================================
# 8. LOCATE OPENOCD CONFIGURATION
# ============================================================

echo
echo "[8/16] Locating OpenOCD configuration files..."

OPENOCD_SCRIPTS=""

for DIR in \
    "/usr/share/openocd/scripts" \
    "/usr/local/share/openocd/scripts" \
    "/opt/openocd/share/openocd/scripts"
do

    if [ -d "$DIR" ]; then
        OPENOCD_SCRIPTS="$DIR"
        break
    fi

done

if [ -n "$OPENOCD_SCRIPTS" ]; then

    echo
    echo "OpenOCD scripts:"
    echo "  $OPENOCD_SCRIPTS"

else

    echo
    echo "WARNING:"
    echo "OpenOCD scripts directory was not found."

fi

# ============================================================
# 9. CHECK XDS110
# ============================================================

echo
echo "[9/16] Checking XDS110 support..."

if [ -n "$OPENOCD_SCRIPTS" ] &&
   [ -f "$OPENOCD_SCRIPTS/interface/xds110.cfg" ]; then

    echo
    echo "XDS110 configuration found:"
    echo
    echo "  $OPENOCD_SCRIPTS/interface/xds110.cfg"

else

    echo
    echo "WARNING:"
    echo "interface/xds110.cfg was not found."

    echo
    echo "OpenOCD may require a TI-specific build for XDS110."
fi

# ============================================================
# 10. CHECK CC26x0 TARGET
# ============================================================

echo
echo "[10/16] Checking CC2650 OpenOCD target..."

CC26_TARGET=""

if [ -n "$OPENOCD_SCRIPTS" ]; then

    for TARGET_CFG in \
        "$OPENOCD_SCRIPTS/target/ti_cc26x0.cfg" \
        "$OPENOCD_SCRIPTS/target/cc26x0.cfg" \
        "$OPENOCD_SCRIPTS/target/ti/cc26x0.cfg"
    do

        if [ -f "$TARGET_CFG" ]; then
            CC26_TARGET="$TARGET_CFG"
            break
        fi

    done

fi

if [ -n "$CC26_TARGET" ]; then

    echo
    echo "CC26x0 target configuration:"
    echo "  $CC26_TARGET"

else

    echo
    echo "WARNING:"
    echo "CC26x0 target configuration was not found."

    echo
    echo "Available CC26 configurations:"
    find "$OPENOCD_SCRIPTS/target" \
        -iname '*cc26*' \
        2>/dev/null || true

fi

# ============================================================
# 11. CLONE CONTIKI-NG
# ============================================================

echo
echo "[11/16] Installing Contiki-NG..."

if [ -d "$CONTIKI_DIR/.git" ]; then

    echo
    echo "Contiki-NG already exists:"
    echo "  $CONTIKI_DIR"

    cd "$CONTIKI_DIR"

    echo
    echo "Updating repository..."

    git pull --ff-only || true

else

    if [ -d "$CONTIKI_DIR" ]; then

        echo
        echo "ERROR:"
        echo "$CONTIKI_DIR exists but is not a Git repository."

        exit 1
    fi
    git clone \
	--recursive https://github.com/contiki-ng/contiki-ng.git \
        "$CONTIKI_DIR"

    cd "$CONTIKI_DIR"

fi

# ============================================================
# 12. INITIALISE CONTIKI-NG SUBMODULES
# ============================================================

echo
echo "[12/16] Initialising Contiki-NG submodules..."

cd "$CONTIKI_DIR"

git lfs install

git submodule update --init --recursive

# ============================================================
# 13. CHECK SIMPLELINK / SENSOR TAG
# ============================================================

echo
echo "[13/16] Checking CC2650 SensorTag support..."

SIMPLELINK_CPU="$CONTIKI_DIR/arch/cpu/simplelink-cc13xx-cc26xx"

if [ ! -d "$SIMPLELINK_CPU" ]; then

    echo
    echo "ERROR:"
    echo "SimpleLink CPU directory not found:"
    echo
    echo "  $SIMPLELINK_CPU"

    exit 1
fi

echo
echo "SimpleLink CPU:"
echo "  OK"

# ------------------------------------------------------------
# Check board using Contiki-NG
# ------------------------------------------------------------

echo
echo "Checking Contiki-NG board list..."

BOARD_LIST="$(make TARGET=simplelink boards 2>/dev/null || true)"

if echo "$BOARD_LIST" | grep -q "sensortag/cc2650"; then

    echo
    echo "SUCCESS:"
    echo "CC2650 SensorTag detected."

else

    echo
    echo "WARNING:"
    echo "sensortag/cc2650 was not found in the board list."

    echo
    echo "SimpleLink boards:"
    echo "$BOARD_LIST"
fi

# ============================================================
# 14. DEVICE PERMISSIONS
# ============================================================

echo
echo "[14/16] Configuring device permissions..."

# ------------------------------------------------------------
# dialout
# ------------------------------------------------------------

if getent group dialout >/dev/null 2>&1; then

    sudo usermod -aG dialout "$USER"

    echo
    echo "Added $USER to dialout."

fi

# ------------------------------------------------------------
# plugdev
# ------------------------------------------------------------

sudo groupadd -f plugdev

sudo usermod -aG plugdev "$USER"

echo
echo "Added $USER to plugdev."

# ------------------------------------------------------------
# XDS110 udev rule
# ------------------------------------------------------------

echo
echo "Creating XDS110 udev rule..."

sudo tee /etc/udev/rules.d/70-xds110.rules > /dev/null <<'EOF'
# ============================================================
# Texas Instruments XDS110
# ============================================================

# TI USB devices
SUBSYSTEM=="usb", ATTR{idVendor}=="0451", MODE="0660", GROUP="plugdev"

# TI serial devices
SUBSYSTEM=="tty", ATTRS{idVendor}=="0451", MODE="0660", GROUP="dialout"
EOF

# ------------------------------------------------------------
# Reload udev
# ------------------------------------------------------------

sudo udevadm control --reload-rules
sudo udevadm trigger

echo
echo "udev rules reloaded."

# ============================================================
# 15. CREATE HELPER SCRIPTS
# ============================================================

echo
echo "[15/16] Creating helper scripts..."

# ------------------------------------------------------------
# Environment
# ------------------------------------------------------------

cat > "$CONTIKI_DIR/env-cc2650-sensortag.sh" <<EOF
#!/usr/bin/env bash

export CONTIKI_NG="$CONTIKI_DIR"
export CONTIKI="$CONTIKI_DIR"

export TARGET=simplelink
export BOARD=sensortag/cc2650

echo
echo "Contiki-NG:"
echo "  \$CONTIKI_NG"

echo
echo "TARGET:"
echo "  \$TARGET"

echo
echo "BOARD:"
echo "  \$BOARD"
EOF

chmod +x "$CONTIKI_DIR/env-cc2650-sensortag.sh"

# ------------------------------------------------------------
# Cooja launcher
# ------------------------------------------------------------

cat > "$CONTIKI_DIR/run-cooja.sh" <<'EOF'
#!/usr/bin/env bash

set -e

CONTIKI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COOJA_DIR="$CONTIKI_DIR/tools/cooja"

echo
echo "============================================================"
echo " Starting Contiki-NG Cooja"
echo "============================================================"
echo

echo "Java:"
java -version

echo
echo "DISPLAY:"
echo "${DISPLAY:-<not set>}"

echo
echo "WAYLAND_DISPLAY:"
echo "${WAYLAND_DISPLAY:-<not set>}"

echo
echo "XDG_SESSION_TYPE:"
echo "${XDG_SESSION_TYPE:-<not set>}"

if [ ! -d "$COOJA_DIR" ]; then

    echo
    echo "ERROR:"
    echo "Cooja directory was not found:"
    echo "  $COOJA_DIR"

    exit 1
fi

cd "$COOJA_DIR"

chmod +x gradlew

echo
echo "Starting Cooja..."
echo

./gradlew run
EOF

chmod +x "$CONTIKI_DIR/run-cooja.sh"

# ------------------------------------------------------------
# Cooja test
# ------------------------------------------------------------

cat > "$CONTIKI_DIR/test-cooja.sh" <<'EOF'
#!/usr/bin/env bash

set -e

CONTIKI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COOJA_DIR="$CONTIKI_DIR/tools/cooja"

echo
echo "============================================================"
echo " Cooja Environment Test"
echo "============================================================"
echo

echo "Java:"
java -version

echo
echo "JAVA_HOME:"
echo "${JAVA_HOME:-<not set>}"

echo
echo "DISPLAY:"
echo "${DISPLAY:-<not set>}"

echo
echo "WAYLAND_DISPLAY:"
echo "${WAYLAND_DISPLAY:-<not set>}"

echo
echo "XDG_SESSION_TYPE:"
echo "${XDG_SESSION_TYPE:-<not set>}"

echo
echo "Cooja directory:"
echo "$COOJA_DIR"

if [ ! -d "$COOJA_DIR" ]; then
    echo
    echo "ERROR: Cooja directory not found."
    exit 1
fi

cd "$COOJA_DIR"

chmod +x gradlew

echo
echo "Gradle wrapper:"
./gradlew --version

echo
echo "Compiling Cooja..."
echo

./gradlew build

echo
echo "============================================================"
echo " Cooja build test successful"
echo "============================================================"
EOF

chmod +x "$CONTIKI_DIR/test-cooja.sh"

# ------------------------------------------------------------
# CC2650 build script
# ------------------------------------------------------------

cat > "$CONTIKI_DIR/build-cc2650-sensortag.sh" <<'EOF'
#!/usr/bin/env bash

set -e

CONTIKI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT="${1:-hello-world}"

PROJECT_DIR="$CONTIKI_DIR/examples/$PROJECT"

echo
echo "============================================================"
echo " CC2650 SensorTag Build"
echo "============================================================"
echo
echo "Project:"
echo "  $PROJECT"
echo
echo "TARGET:"
echo "  simplelink"
echo
echo "BOARD:"
echo "  sensortag/cc2650"
echo

if [ ! -d "$PROJECT_DIR" ]; then

    echo "ERROR:"
    echo "Project not found:"
    echo "  $PROJECT_DIR"

    exit 1
fi

cd "$PROJECT_DIR"

make clean || true

make \
    TARGET=simplelink \
    BOARD=sensortag/cc2650

echo
echo "============================================================"
echo " BUILD SUCCESSFUL"
echo "============================================================"
echo

find "$PROJECT_DIR/build" \
    -maxdepth 5 \
    -type f \
    \( -name "*.elf" -o -name "*.bin" -o -name "*.hex" \) \
    -print
EOF

chmod +x "$CONTIKI_DIR/build-cc2650-sensortag.sh"

# ------------------------------------------------------------
# XDS110 test
# ------------------------------------------------------------

cat > "$CONTIKI_DIR/test-xds110.sh" <<'EOF'
#!/usr/bin/env bash

echo
echo "============================================================"
echo " XDS110 TEST"
echo "============================================================"
echo

echo "USB devices:"
echo

lsusb

echo
echo "TI/XDS devices:"
lsusb | grep -Ei "Texas Instruments|0451|XDS110" || true

echo
echo "Serial devices:"
ls -l /dev/ttyACM* 2>/dev/null || \
    echo "No /dev/ttyACM devices currently detected."

echo
echo "OpenOCD:"
openocd --version 2>&1 | head -n 1

echo
echo "XDS110 configuration:"
if [ -f /usr/share/openocd/scripts/interface/xds110.cfg ]; then
    echo "FOUND"
    echo "/usr/share/openocd/scripts/interface/xds110.cfg"
else
    echo "NOT FOUND"
fi

echo
echo "Attempting XDS110 detection..."
echo

openocd \
    -f interface/xds110.cfg \
    -c "adapter speed 2500" \
    -c "xds110 info" \
    -c "shutdown"

echo
echo "XDS110 test completed."
EOF

chmod +x "$CONTIKI_DIR/test-xds110.sh"

# ------------------------------------------------------------
# Flash script
# ------------------------------------------------------------

cat > "$CONTIKI_DIR/flash-cc2650-sensortag.sh" <<'EOF'
#!/usr/bin/env bash

set -e

CONTIKI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT="${1:-hello-world}"

PROJECT_DIR="$CONTIKI_DIR/examples/$PROJECT"

BUILD_DIR="$PROJECT_DIR/build/simplelink/sensortag/cc2650"

ELF_FILE="$BUILD_DIR/$PROJECT.elf"

echo
echo "============================================================"
echo " CC2650 SensorTag FLASH"
echo "============================================================"
echo

echo "Project:"
echo "  $PROJECT"

echo
echo "ELF:"
echo "  $ELF_FILE"

echo
echo "Debugger:"
echo "  XDS110"

echo
echo "Interface:"
echo "  SWD"

# ------------------------------------------------------------
# Check ELF
# ------------------------------------------------------------

if [ ! -f "$ELF_FILE" ]; then

    echo
    echo "ERROR:"
    echo "ELF file not found:"
    echo
    echo "  $ELF_FILE"
    echo
    echo "Build first:"
    echo
    echo "  ./build-cc2650-sensortag.sh"
    echo

    exit 1
fi

# ------------------------------------------------------------
# Check XDS110 configuration
# ------------------------------------------------------------

if [ ! -f "/usr/share/openocd/scripts/interface/xds110.cfg" ]; then

    echo
    echo "ERROR:"
    echo "OpenOCD XDS110 configuration not found:"
    echo
    echo "  /usr/share/openocd/scripts/interface/xds110.cfg"
    echo

    exit 1
fi

# ------------------------------------------------------------
# Find CC26x0 target
# ------------------------------------------------------------

if [ -f "/usr/share/openocd/scripts/target/ti_cc26x0.cfg" ]; then

    TARGET_CFG="target/ti_cc26x0.cfg"

elif [ -f "/usr/share/openocd/scripts/target/cc26x0.cfg" ]; then

    TARGET_CFG="target/cc26x0.cfg"

else

    echo
    echo "ERROR:"
    echo "CC26x0 OpenOCD target configuration not found."

    echo
    echo "Available files:"
    find /usr/share/openocd/scripts/target \
        -iname "*cc26*" \
        2>/dev/null || true

    exit 1
fi

echo
echo "Target configuration:"
echo "  $TARGET_CFG"

# ------------------------------------------------------------
# Flash
# ------------------------------------------------------------

echo
echo "Programming CC2650..."
echo

openocd \
    -f interface/xds110.cfg \
    -f "$TARGET_CFG" \
    -c "transport select swd" \
    -c "adapter speed 2500" \
    -c "init" \
    -c "reset halt" \
    -c "program $ELF_FILE verify" \
    -c "reset run" \
    -c "shutdown"

echo
echo "============================================================"
echo " FLASH SUCCESSFUL"
echo "============================================================"
EOF

chmod +x "$CONTIKI_DIR/flash-cc2650-sensortag.sh"

# ------------------------------------------------------------
# Build + flash
# ------------------------------------------------------------

cat > "$CONTIKI_DIR/build-and-flash-cc2650-sensortag.sh" <<'EOF'
#!/usr/bin/env bash

set -e

CONTIKI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT="${1:-hello-world}"

"$CONTIKI_DIR/build-cc2650-sensortag.sh" "$PROJECT"

"$CONTIKI_DIR/flash-cc2650-sensortag.sh" "$PROJECT"
EOF

chmod +x "$CONTIKI_DIR/build-and-flash-cc2650-sensortag.sh"

# ============================================================
# FINAL TESTS
# ============================================================

echo
echo "[16/16] Performing installation checks..."

echo
echo "============================================================"
echo " VERSION CHECK"
echo "============================================================"

echo
echo "ARM GCC:"
arm-none-eabi-gcc --version | head -n 1

echo
echo "OpenOCD:"
openocd --version 2>&1 | head -n 1

echo
echo "Java:"
java -version 2>&1 | head -n 1

echo
echo "Python:"
python3 --version

echo
echo "Git:"
git --version

# ------------------------------------------------------------
# Check Gradle wrapper
# ------------------------------------------------------------

COOJA_DIR="$CONTIKI_DIR/tools/cooja"

if [ -d "$COOJA_DIR" ]; then

    echo
    echo "Cooja:"
    echo "  FOUND"

    cd "$COOJA_DIR"

    chmod +x gradlew

    echo
    echo "Gradle wrapper:"
    ./gradlew --version || true

else

    echo
    echo "WARNING:"
    echo "Cooja directory was not found."
fi

# ============================================================
# SUMMARY
# ============================================================

echo
echo
echo "============================================================"
echo " INSTALLATION COMPLETE"
echo "============================================================"
echo

echo "Contiki-NG:"
echo "  $CONTIKI_DIR"

echo
echo "CC2650:"
echo "  SensorTag"

echo
echo "Contiki target:"
echo "  TARGET=simplelink"

echo
echo "Contiki board:"
echo "  BOARD=sensortag/cc2650"

echo
echo "Debugger:"
echo "  XDS110"

echo
echo "Flash interface:"
echo "  SWD"

echo
echo "Cooja:"
echo "  $CONTIKI_DIR/tools/cooja"

echo
echo "============================================================"
echo " COMMANDS"
echo "============================================================"

echo
echo "1. Reboot:"
echo
echo "   sudo reboot"

echo
echo "2. Test XDS110:"
echo
echo "   cd ~/contiki-ng"
echo "   ./test-xds110.sh"

echo
echo "3. Test Cooja:"
echo
echo "   ./test-cooja.sh"

echo
echo "4. Launch Cooja:"
echo
echo "   ./run-cooja.sh"

echo
echo "5. Build CC2650 SensorTag:"
echo
echo "   ./build-cc2650-sensortag.sh"

echo
echo "6. Flash CC2650 SensorTag:"
echo
echo "   ./flash-cc2650-sensortag.sh"

echo
echo "7. Build and flash:"
echo
echo "   ./build-and-flash-cc2650-sensortag.sh"

echo
echo "============================================================"
echo
echo "IMPORTANT:"
echo "Do NOT run this installation script with sudo."
echo
echo "Run it as your normal user:"
echo
echo "   ./install-contiki-cc2650-sensortag-xds110.sh"
echo
echo "The script uses sudo internally where necessary."
echo
echo "============================================================"




echo "UPDATING THE MAKEFILE..."

```bash
#!/usr/bin/env bash

# ============================================================
# Fix Contiki-NG CC26x0 PRIx64 / Newlib compatibility
#
# Adds:
#   CFLAGS += -D__int64_t_defined
#
# to:
#   arch/cpu/cc26x0-cc13x0/Makefile.cc26x0
#
# ============================================================

set -e

CONTIKI_DIR="$HOME/contiki-ng"
MAKEFILE="$CONTIKI_DIR/arch/cpu/cc26x0-cc13x0/Makefile.cc26x0"

echo
echo "============================================================"
echo " Contiki-NG CC26x0 Makefile Fix"
echo "============================================================"
echo

# ------------------------------------------------------------
# Check Contiki-NG
# ------------------------------------------------------------

if [ ! -d "$CONTIKI_DIR" ]; then
    echo "ERROR: Contiki-NG directory not found:"
    echo "  $CONTIKI_DIR"
    exit 1
fi

# ------------------------------------------------------------
# Check Makefile
# ------------------------------------------------------------

if [ ! -f "$MAKEFILE" ]; then
    echo "ERROR: Makefile not found:"
    echo "  $MAKEFILE"
    exit 1
fi

echo "Makefile:"
echo "  $MAKEFILE"

# ------------------------------------------------------------
# Check if fix already exists
# ------------------------------------------------------------

if grep -q -- "-D__int64_t_defined" "$MAKEFILE"; then

    echo
    echo "The fix is already present:"
    echo
    grep -n -- "-D__int64_t_defined" "$MAKEFILE"

    echo
    echo "No changes made."
    exit 0
fi

# ------------------------------------------------------------
# Create backup
# ------------------------------------------------------------

BACKUP="${MAKEFILE}.backup.$(date +%Y%m%d_%H%M%S)"

cp "$MAKEFILE" "$BACKUP"

echo
echo "Backup created:"
echo "  $BACKUP"

# ------------------------------------------------------------
# Check expected line
# ------------------------------------------------------------

EXPECTED='CFLAGS += -DCPU_FAMILY_CC26X0=1 -DCPU_FAMILY_CC26XX=1'

if ! grep -Fq "$EXPECTED" "$MAKEFILE"; then

    echo
    echo "ERROR: Expected CFLAGS line was not found."
    echo
    echo "Expected:"
    echo "  $EXPECTED"
    echo
    echo "The Makefile has NOT been modified."
    echo
    echo "Current CFLAGS lines:"
    grep -n "CFLAGS" "$MAKEFILE" || true

    exit 1
fi

# ------------------------------------------------------------
# Add compatibility flag
# ------------------------------------------------------------

sed -i \
    "/CFLAGS += -DCPU_FAMILY_CC26X0=1 -DCPU_FAMILY_CC26XX=1/a CFLAGS += -D__int64_t_defined" \
    "$MAKEFILE"

# ------------------------------------------------------------
# Verify
# ------------------------------------------------------------

echo
echo "Updated Makefile:"
echo

grep -n "CFLAGS" "$MAKEFILE"

if grep -q -- "-D__int64_t_defined" "$MAKEFILE"; then

    echo
    echo "============================================================"
    echo " SUCCESS"
    echo "============================================================"
    echo
    echo "Added:"
    echo "  CFLAGS += -D__int64_t_defined"
    echo
    echo "Backup:"
    echo "  $BACKUP"
    echo

else

    echo
    echo "ERROR: Failed to update Makefile."

    # Restore backup
    cp "$BACKUP" "$MAKEFILE"

    echo
    echo "Original Makefile restored."

    exit 1
fi
```
