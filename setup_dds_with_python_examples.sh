#!/bin/bash

set -e

echo "=========================================="
echo "     Cyclone DDS Demo Installation"
echo "=========================================="

# ------------------------------------------
# 1. Install system requirements
# ------------------------------------------

echo
echo "[1/6] Installing system requirements..."

sudo apt update

sudo apt install -y \
    python3 \
    python3-venv \
    python3-pip \
    cyclonedds-dev


# ------------------------------------------
# 2. Create DDS_Demo directory
# ------------------------------------------

echo
echo "[2/6] Creating DDS_Demo directory..."

mkdir -p DDS_Demo
cd DDS_Demo

echo "Working directory: $(pwd)"


# ------------------------------------------
# 3. Create Python virtual environment
# ------------------------------------------

echo
echo "[3/6] Creating Python virtual environment..."

python3 -m venv dds-env


# ------------------------------------------
# 4. Activate environment
# ------------------------------------------

echo
echo "[4/6] Activating virtual environment..."

source dds-env/bin/activate


# ------------------------------------------
# 5. Install Cyclone DDS Python package
# ------------------------------------------

echo
echo "[5/6] Installing Cyclone DDS for Python..."

python -m pip install --upgrade pip
python -m pip install cyclonedds


# ------------------------------------------
# 6. Create DDS programs
# ------------------------------------------

echo
echo "[6/6] Creating example programs..."


# ==========================================
# sensor_type.py
# ==========================================

cat > sensor_type.py <<'EOF'
from dataclasses import dataclass
import cyclonedds.idl as idl
import cyclonedds.idl.annotations as annotate


@dataclass
class SensorReading(idl.IdlStruct):
    sensor_id: int
    annotate.key("sensor_id")
    location: str
    temperature: float
    humidity: float
    timestamp: int
EOF


# ==========================================
# publisher_ex.py
# ==========================================

cat > publisher_ex.py <<'EOF'
import time

from cyclonedds.domain import DomainParticipant
from cyclonedds.topic import Topic
from cyclonedds.pub import DataWriter

from sensor_type import SensorReading


def main():

    # Join DDS Domain 0
    dp = DomainParticipant(0)

    # Create DDS Topic
    topic = Topic(
        dp,
        "Environment/SensorReadings",
        SensorReading
    )

    # Create DataWriter (Publisher)
    writer = DataWriter(dp, topic)

    print("--------------------------------------")
    print(" DDS Publisher")
    print("--------------------------------------")
    print("Sending sensor readings...")
    print("Press Ctrl+C to stop.\n")

    sensor_id = 101
    counter = 0

    try:

        while True:

            sample = SensorReading(
                sensor_id=sensor_id,
                location="Lab-01",
                temperature=22.5 + (counter % 5) * 0.2,
                humidity=55.0 + (counter % 3),
                timestamp=int(time.time())
            )

            writer.write(sample)

            print(
                f"[PUB] Sent: "
                f"ID={sample.sensor_id} | "
                f"Location={sample.location} | "
                f"Temp={sample.temperature:.1f} C | "
                f"Humidity={sample.humidity:.1f}%"
            )

            counter += 1

            time.sleep(1)

    except KeyboardInterrupt:

        print("\nPublisher stopped.")


if __name__ == "__main__":
    main()
EOF


# ==========================================
# subscriber_ex.py
# ==========================================

cat > subscriber_ex.py <<'EOF'
import time

from cyclonedds.domain import DomainParticipant
from cyclonedds.topic import Topic
from cyclonedds.sub import DataReader

from sensor_type import SensorReading


def main():

    # Join the same DDS Domain
    dp = DomainParticipant(0)

    # Subscribe to the same Topic
    topic = Topic(
        dp,
        "Environment/SensorReadings",
        SensorReading
    )

    # Create DataReader (Subscriber)
    reader = DataReader(dp, topic)

    print("--------------------------------------")
    print(" DDS Subscriber")
    print("--------------------------------------")
    print("Waiting for sensor readings...")
    print("Press Ctrl+C to stop.\n")

    try:

        while True:

            for sample in reader.take():

                print(
                    f"[SUB] Received: "
                    f"ID={sample.sensor_id} | "
                    f"Location={sample.location} | "
                    f"Temp={sample.temperature:.1f} C | "
                    f"Humidity={sample.humidity:.1f}%"
                )

            time.sleep(0.2)

    except KeyboardInterrupt:

        print("\nSubscriber stopped.")


if __name__ == "__main__":
    main()
EOF


# ------------------------------------------
# Verify installation
# ------------------------------------------

echo
echo "Checking Cyclone DDS installation..."

python -c "import cyclonedds; print('Cyclone DDS Python: OK')"


# ------------------------------------------
# Finished
# ------------------------------------------

echo
echo "=========================================="
echo "       Installation Complete!"
echo "=========================================="
echo
echo "Everything has been installed in:"
echo
echo "  $(pwd)"
echo
echo "Directory structure:"
echo
echo "DDS_Demo/"
echo " |"
echo " +-- dds-env/"
echo " +-- sensor_type.py"
echo " +-- publisher_ex.py"
echo " +-- subscriber_ex.py"
echo
echo "=========================================="
echo " RUNNING THE DDS DEMO"
echo "=========================================="
echo
echo "Open Terminal 1:"
echo
echo "  cd $(pwd)"
echo "  source dds-env/bin/activate"
echo "  python subscriber_ex.py"
echo
echo "Open Terminal 2:"
echo
echo "  cd $(pwd)"
echo "  source dds-env/bin/activate"
echo "  python publisher_ex.py"
echo
echo "=========================================="
