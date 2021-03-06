#!/bin/sh
# Various functions for initializing modem and querying ISP parameters 

# Variables
#----------
CHAT_CMD=/usr/sbin/chat
# Modem device settings
DEVICE_NODE=ttyUSB
DEVICE_NODE_PATH=/dev/$DEVICE_NODE
#
# Wait for device nodes to appear before proceeding
ls $DEVICE_NODE_PATH* > /dev/null 2>&1
NODE_STATUS=$?
while [ "$NODE_STATUS" != "0" ];
do
# Wait for 1 second
echo "Waiting for modem to be recognized by system, please wait ..."
sleep 5
ls $DEVICE_NODE_PATH* > /dev/null 2>&1
NODE_STATUS=$?
done
#
# Modem data port
for DEVICE_NODE_NO in `seq 0 5`
do
# Ensure device path is a character device
[ -c $DEVICE_NODE_PATH$DEVICE_NODE_NO ] || break
$CHAT_CMD -t 1 -EVv "" "ATZ" "OK" "" > $DEVICE_NODE_PATH$DEVICE_NODE_NO 2>&1 < $DEVICE_NODE_PATH$DEVICE_NODE_NO
DEVICE_NODE_STATUS_1=$?
# Set MODEMDEV if found
if [ "$DEVICE_NODE_STATUS_1" = "0" ];
then
MODEMDEV=$DEVICE_NODE_PATH$DEVICE_NODE_NO
break
fi
done
#
# Modem control port
let "LAST_DEVICE_NODE_NO =  $DEVICE_NODE_NO + 1"
for DEVICE_NODE_NO in `seq $LAST_DEVICE_NODE_NO 5`
do
# Ensure device path is a character device
[ -c $DEVICE_NODE_PATH$DEVICE_NODE_NO ] || break
$CHAT_CMD -t 1 -EVv "" "ATZ" "OK" "" > $DEVICE_NODE_PATH$DEVICE_NODE_NO 2>&1 < $DEVICE_NODE_PATH$DEVICE_NODE_NO
DEVICE_NODE_STATUS_2=$?
# Set MODEMCONTROLDEV if found
if [ "$DEVICE_NODE_STATUS_2" = "0" ];
then
MODEMCONTROLDEV=$DEVICE_NODE_PATH$DEVICE_NODE_NO
break
fi
done
#
# Export modem variables
export MODEMDEV MODEMCONTROLDEV DEVICE_NODE DEVICE_NODE_NO



# Reset modem 
reset_modem () {
$CHAT_CMD -EVv "" "ATZ" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Put modem on-line
set_modem_online () {
$CHAT_CMD -EVv "" "AT+CFUN=1" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Query for manufacturer of modem
query_modem_brand () {
$CHAT_CMD -EVv "" "AT+CGMI" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Query for model no. of modem
query_modem_model () {
$CHAT_CMD -EVv "" "AT+CGMM" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Query for hardware version of modem
query_modem_hardware_vers () {
$CHAT_CMD -EVv "" "AT\^HWVER" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Query for firmware version of modem
query_modem_firmware_vers () {
$CHAT_CMD -EVv "" "AT+CGMR" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Query for device EMEI Number
query_modem_emei () {
$CHAT_CMD -EVv "" "AT+CGSN" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Query for device Serial Number
query_modem_serial () {
$CHAT_CMD -EVv "" "AT+CGSN" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Query for SIM IMSI Number
query_sim_imsi () {
$CHAT_CMD -t 1 -EVv "" "AT+CIMI" "OK" "" > $MODEMDEV < $MODEMDEV
SIM_STATUS=$?
}

# Query for Card Lock Statis
query_modem_lock () {
$CHAT_CMD -EVv "" "AT\^CARDLOCK?" "OK" "" > $MODEMDEV < $MODEMDEV
# 1- Locked
# 2- Unlocked
# 3- Unlocked foorever
}

# Query for available APNs
query_modem_apn () {
$CHAT_CMD -EVv "" "AT+CGDCONT?" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Set network type
set_network_type () {
$CHAT_CMD -EVv "" "AT" "OK" "" > $MODEMDEV < $MODEMDEV
$CHAT_CMD -EVv "" "AT\^SYSCFG=$@" "OK" "" > $MODEMDEV < $MODEMDEV
}

# Query for available networks
query_networks () {
$CHAT_CMD -EVv "" "AT+COPS=?" "OK" "" > $MODEMDEV < $MODEMDEV
}
