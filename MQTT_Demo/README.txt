#
# Vara added the instructions below
#
# The referred program is from:
# ~/contiki-ng/examples/platform-specific/cc26x0-cc13x0/base-demo/base-demo.c
#
# To compile the program:
# make TARGET=cc26x0-cc13x0 BOARD=sensortag/cc2650
#
# To flash the binary:
# ./flash_cc2650.sh /home/ict3207/contiki-ng/examples/platform-specific/cc26x0-cc13x0/base-demo/build/cc26x0-cc13x0/sensortag/cc2650/base-demo.cc26x0-cc13x0
#
# Then the script, test_mqtt_pub_from_serial.sh, that will publish the sensor data to vara.hopto.org 
#
# To subscribe
# mosquitto_sub -h vara.hopto.org -t /rooms/room1/sensors/# -p 8080
#
