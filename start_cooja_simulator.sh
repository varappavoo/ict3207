#!/bin/bash

CONTIKI_NG="/home/ict3207/contiki-ng"
COOJA="$CONTIKI_NG/tools/cooja"

if [ ! -d "$COOJA" ]; then
    echo "ERROR: Cooja directory not found:"
    echo "  $COOJA"
    exit 1
fi

echo "Starting Cooja..."
echo "Contiki-NG: $CONTIKI_NG"
echo

cd "$COOJA" || exit 1

./gradlew run
