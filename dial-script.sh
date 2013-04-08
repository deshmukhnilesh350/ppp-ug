#!/bin/sh
# This script will dial a Ugandan ISP and provide you with its network details
# You need the following scripts also
# chat-script.sh     modem_isp_init.sh
#
# Copyright (C) 2012 Joseph Zikusooka.
#
# Contact me at: joseph AT zikusooka.com

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.



# My Preferences
# --------------
ISP=$1 
ACCOUNT=$2	
PASSWORD=$3	
NETWORK_TYPE_BAND_OPTION=$4


# Unique ISP PPP options
#------------------------
case $ISP in
# UTL
[Uu][Tt][Ll]) 
APN=UTBROADBAND
USE_PEER_DNS=y
DNS1=81.199.21.94
DNS2=81.199.31.33
MRU_SIZE=576 
MTU_SIZE=576 
;;
# Orange
[Oo][Rr][Aa][Nn][Gg][Ee])
APN="orange.ug"
USE_PEER_DNS=n  # Important - DNS for orange not allocated properly!
DNS1=41.202.229.144
DNS2=41.202.229.140
MRU_SIZE=1452
MTU_SIZE=1452
;;
# MTN
[Mm][Tt][Nn])
APN="yelloaccess.co.ug"
USE_PEER_DNS=y
DNS1=212.88.97.20
DNS2=193.108.214.50
MRU_SIZE=576 
MTU_SIZE=576 
;;
# Airtel
[Aa][Ii][Rr][Tt][Ee][Ll])
APN="celtel.co.ug"
USE_PEER_DNS=y
DNS1=217.113.72.20 # Verify with ISP
DNS2=217.113.72.21 # Verify with ISP
MRU_SIZE=576 
MTU_SIZE=576
;;
# Warid
[Ww][Aa][Rr][Ii][Dd])
APN="Warid"
USE_PEER_DNS=y
DNS1=41.221.87.2
DNS2=41.221.81.132
MRU_SIZE=576 
MTU_SIZE=576
;;
esac


# Fixed Variables 
# ---------------
THIS_SCRIPT=`basename $0`
PPP_SCRIPTS_PATH=`find ${HOME} -name $THIS_SCRIPT`
PPP_SCRIPTS_DIR=`dirname $PPP_SCRIPTS_PATH`
DIALER_SCRIPT=$PPP_SCRIPTS_DIR/chat-script.sh
MODEM_ISP_INIT_SCRIPT=$PPP_SCRIPTS_DIR/modem_isp_init.sh
TELEPHONE="*99#"	# The telephone number for the connection
PROTOCOL=PPP            # The protocol to satrt after connection
LOCAL_IP=0.0.0.0	# Local IP address if known. Dynamic = 0.0.0.0
REMOTE_IP=0.0.0.0	# Remote IP address if desired. Normally 0.0.0.0
NETMASK=255.255.255.0	# The proper netmask if needed
SPEED=460800		# Try 921600

PPP_PIDFILE=/var/run/ppp0.pid

PPP_LOG_FILE=/var/log/ppp/ppp.log
SYS_LOG_FILE=/var/log/messages
IPTABLES=/sbin/iptables
REMOTE_DOMAIN_NAME=google.com
AVAILABLE_NETWORKS_FILE=/tmp/ppp_available_networks_all
DATE_TIMESTAMP=`date +"%b %d at %I:%M:%S"`

DSFLOWRPT_STATS_FILE=/var/log/ppp/statistics.log
DSFLOWRPT_HEX_TMP_FILE=/tmp/dsflowrpt_ppp






###############
#  FUNCTIONS  #
###############

command_usage(){
echo "Usage:  ./`basename $0` [ISP_NAME] [USERNAME] [PASSWORD] [NETWORK_TYPE]
Example:./`basename $0` UTL irene@3g secret 1

ISP Names
--------- 
UTL ORANGE MTN AIRTEL WARID

Network Types
-------------
1 - 3G/WCDMA Only
2 - 2G/GPRS Only
3 - 3G/WCDMA Preferred
4 - 2G/GPRS Preferred
"
}

if [ "x$1" = "x" ];
then
command_usage
exit 1
elif [ "x$2" = "x" ];
then
command_usage
exit 1
elif [ "x$3" = "x" ];
then
command_usage
exit 1
elif [ "x$4" = "x" ];
then
command_usage
exit 1
fi


# Dig Host
dig_host () {
host $REMOTE_DOMAIN_NAME > /dev/null 2>&1
STATUS=$?
}


# CLI Calculator
calc(){ 
awk "BEGIN{ print $* }" 
}


# Source modem ISP initialization scripts
. $MODEM_ISP_INIT_SCRIPT

# Source modem device
MODEM_LOCKFILE=/var/lock/LCK..$DEVICE


# Network Type/Band Selection
# ---------------------------
# AT^SYSCFG=mode,order,band,roam,domain
case $NETWORK_TYPE_BAND_OPTION in
1)
NETWORK_TYPE_BAND="14,2,3FFFFFFF,1,2" # 3G -WCDMA Only
;;
2)                
NETWORK_TYPE_BAND="13,1,3FFFFFFF,1,2" # 2G - GPRS/EDGE Only
;;
3)
NETWORK_TYPE_BAND="2,2,3FFFFFFF,1,2" # 3G Preferred
;;
4)
NETWORK_TYPE_BAND="2,1,3FFFFFFF,1,2" # GPRS/EDGE Preferred
;;
*)
NETWORK_TYPE_BAND="14,2,3FFFFFFF,1,2" # 3G -WCDMA Only
;;
esac






#################
#  MAIN SCRIPT  #
#################

# Proceed only after device is found
while [ ! -c /dev/$DEVICE ];
do
echo "Waiting for modem to be recognized by system, please wait ..."
sleep 2
. $MODEM_ISP_INIT_SCRIPT
done

# Quick Modem information
# ----------------------- 

# Reset modem 
echo "
Initializing the modem
----------------------"
reset_modem
echo


# Take modem to on-line status
echo "
Setting the modem on-line
-------------------------"
set_modem_online 
echo


# Modem Manufacturer
echo "
The manufacturer of the modem is
--------------------------------"
query_modem_brand


# Modem Model Number
echo "
The model number of the modem is
--------------------------------"
query_modem_model


# Hardware version
echo "
The hardware version of the modem is
------------------------------------"
query_modem_hardware_vers


# Firmware version
echo "
The firmware version of the modem is
------------------------------------"
query_modem_firmware_vers


# IMSI Number of SIM
echo "
The SIM IMSI number is
----------------------"
query_sim_imsi


# EMEI Number of modem
echo "
The EMEI number of the modem is
-------------------------------"
query_modem_emei


# Lock status of modem
echo "
The Lock status of the modem is
-------------------------------"
query_modem_lock 


# Available APNs
echo "
Querying for available APNs
---------------------------"
query_modem_apn




# Set Network Mode - Start with preferred
echo "
Setting Network Type (mode) to [$NETWORK_TYPE_BAND]
--------------------------------------------------------"
set_network_type $NETWORK_TYPE_BAND


# Query ISP Network type
echo "
Querying for Available Networks
-------------------------------"
query_networks > $AVAILABLE_NETWORKS_FILE 2>&1



# Set determined ISP variables
AVAILABLE_NETWORK=`grep '+COPS:' $AVAILABLE_NETWORKS_FILE | cut -d ':' -f2-99 | grep -i $ISP | cut -d '(' -f2 | sed -e 's/),//g'`
network_id_no=`echo $AVAILABLE_NETWORK | cut -d ',' -f1`
network_name=`echo $AVAILABLE_NETWORK | cut -d ',' -f3 | sed -e 's/"//g'`
network_mode_no=`echo $AVAILABLE_NETWORK | cut -d ',' -f5`
NETWORK_ID_STRING="0,0,\\\"$network_name\\\",$network_mode_no"



# Proceed to connect
clear
echo "`date +"%b %d at %I:%M:%S"`
---
Registering to [$AVAILABLE_NETWORK].  Please be patient ..."


# Export all variables so that they will be available at 'chat-script' time.
# (MUST BE AFTER THE Dynamic variables!)
export TELEPHONE ACCOUNT PASSWORD PROTOCOL ISP APN NETWORK_ID_STRING NETWORK_TYPE_BAND



#  CONNECTIVITY LOOP  
#  ------------------

# Check to see if Internet is already accessible
dig_host

# Start Run counter
PPPD_RUN=1

while [ "$STATUS" != "0" ];
do

# Kill any existing PPP processes
ps acx | grep pppd > /dev/null || killall -9 pppd > /dev/null 2>&1 
[ ! -f $PPP_PIDFILE ] || kill -9 `cat $PPP_PIDFILE` > /dev/null 2>&1

# remove MODEM_LOCKFILE
[ ! -f "$MODEM_LOCKFILE" ] || rm -f $MODEM_LOCKFILE

# Delete Default Route
/sbin/route del default > /dev/null 2>&1



# Run pppd
# --------
if [ "$USE_PEER_DNS" = "y" ];
then
/usr/sbin/pppd debug logfile $PPP_LOG_FILE lock modem crtscts \
	mru $MRU_SIZE mtu $MTU_SIZE updetach nomagic \
	asyncmap a0000 defaultroute usepeerdns $MODEMDEV $SPEED \
	noipdefault noauth user $ACCOUNT password $PASSWORD \
	$LOCAL_IP:$REMOTE_IP connect $DIALER_SCRIPT
else
/usr/sbin/pppd debug logfile $PPP_LOG_FILE lock modem crtscts \
	mru $MRU_SIZE mtu $MTU_SIZE updetach nomagic \
	asyncmap a0000 defaultroute $MODEMDEV $SPEED \
	noipdefault noauth user $ACCOUNT password $PASSWORD \
	$LOCAL_IP:$REMOTE_IP connect $DIALER_SCRIPT
fi
PPP_EXIT_STATUS=$?



# PPP Exit Status's
case $PPP_EXIT_STATUS in
0)      
PPP_ERROR_MSG="Pppd  has detached, or otherwise the connection was successfully established and terminated at the peer’s request."
;;
1)      
PPP_ERROR_MSG="An immediately fatal error of some kind  occurred, such as an essential system call failing, or running out of virtual memory"
;;
2)
PPP_ERROR_MSG="An error was detected in processing the options given, such as two mutually exclusive options being used."
;;
3)
PPP_ERROR_MSG="Pppd is not setuid-root and the invoking user is not root."
;;
4)      
PPP_ERROR_MSG="The  kernel  does  not  support PPP, for example, the PPP kernel driver is not included or cannot be loaded."
;;
5) 
PPP_ERROR_MSG="Pppd terminated because it was sent a SIGINT, SIGTERM or  SIGHUP signal."
;;
6)
PPP_ERROR_MSG="The serial port could not be locked."
;;
7)
PPP_ERROR_MSG="The serial port could not be opened."
;;
8)      
PPP_ERROR_MSG="The connect script failed (returned a non-zero exit status)."
;;
9)      
PPP_ERROR_MSG="The command specified as the argument to the pty option could not be run."
;;
10)     
PPP_ERROR_MSG="The PPP negotiation failed, that is, it didn’t reach  the  point where at least one network protocol (e.g. IP) was running."
;;
11)
PPP_ERROR_MSG="The peer system failed (or refused) to authenticate itself."
;;
12)     
PPP_ERROR_MSG="The  link was established successfully and terminated because it was idle."
;;
13)     
PPP_ERROR_MSG="The link was established successfully and terminated because the connect time limit was reached."
;;
14)     
PPP_ERROR_MSG="Callback  was  negotiated  and  an  incoming  call should arrive shortly."
;;
15)     
PPP_ERROR_MSG="The link was terminated because the peer is not  responding to echo requests."
;;
16)     
PPP_ERROR_MSG="The link was terminated by the modem hanging up."
;;
17)
PPP_ERROR_MSG="The PPP negotiation failed because serial loopback was detected."
;;
18)     
PPP_ERROR_MSG="The init script failed (returned a non-zero exit status)."
;;
19)     
PPP_ERROR_MSG="We failed to authenticate ourselves to the peer."
;;
*)     
PPP_ERROR_MSG="Unknown"
;;
esac



# DNS Settings
# ------------
# Add DNS entries for ISPs like orange that may not do so
if [ "$USE_PEER_DNS" = "n" ];
then
echo "# $ISP DNS Settings
nameserver $DNS1
nameserver $DNS2" > /etc/resolv.conf
# Set DNS for echoing later
PRIMARY_DNS_ADDRESS=$DNS1
SECONDARY_DNS_ADDRESS=$DNS2
else
PRIMARY_DNS_ADDRESS=`cat $PPP_LOG_FILE | grep 'primary   DNS address' | tail -n 1 | awk {'print $4'}`
SECONDARY_DNS_ADDRESS=`cat $PPP_LOG_FILE | grep 'secondary DNS address' | tail -n 1 | awk {'print $4'}`
fi


# Determine Signal Strength & other operator's network settings
# -------------------------------------------------------------
SIGNAL_STRENGTH=`grep 'CSQ' $PPP_LOG_FILE | tail -n 1 | cut -d ':' -f2 | cut -d ',' -f1`
SERVICE_STATUS=`grep 'SYSINFO' $PPP_LOG_FILE | tail -n 1 | cut -d ':' -f2 | cut -d ',' -f1`
SERVICE_DOMAIN=`grep 'SYSINFO' $PPP_LOG_FILE | tail -n 1 | cut -d ':' -f2 | cut -d ',' -f2`
ROAMING_STATUS=`grep 'SYSINFO' $PPP_LOG_FILE | tail -n 1 | cut -d ':' -f2 | cut -d ',' -f3`
SERVICE_MODE=`grep 'SYSINFO' $PPP_LOG_FILE | tail -n 1 | cut -d ':' -f2 | cut -d ',' -f4`
SIM_STATE=`grep 'SYSINFO' $PPP_LOG_FILE | tail -n 1 | cut -d ':' -f2 | cut -d ',' -f5`
#ACTIVE_NETWORK=`grep '+COPS:' $PPP_LOG_FILE | tail -n 1 | cut -d ':' -f2 | sed -e "s/ //g"`
SIGNAL_QUALITY=`calc $SIGNAL_STRENGTH/31*100 | cut -d '.' -f1`.`calc $SIGNAL_STRENGTH/31*100 | cut -d '.' -f2 | cut -b1`%

# ISP Link Parameters
REMOTE_CHAP_SERVER=`cat $PPP_LOG_FILE | grep 'CHAP Challenge' | tail -n 1 | cut -d "=" -f3 | sed -e "s/]//g" | sed -e "s/\"//g"`
LOCAL_IP_ADDRESS=`cat $PPP_LOG_FILE | grep 'local  IP address' | tail -n 1 | awk {'print $4'}`
REMOTE_IP_ADDRESS=`cat $PPP_LOG_FILE | grep 'remote IP address' | tail -n 1 | awk {'print $4'}`
PPP_INTERFACE=`grep Connect: $PPP_LOG_FILE  | tail -1 | cut -d : -f2 | awk {'print $1'}`
REMOTE_MTU=`ifconfig | grep $PPP_INTERFACE | grep -i MTU | awk {'print $4'}`

# Query Service mode i.e. connection type
case $SERVICE_MODE in
3)
SIGNAL_TYPE="GSM/GPRS (2G)"
;;
5)
SIGNAL_TYPE="WCDMA (3G)"
;;
7)
SIGNAL_TYPE="GSM/WCDMA (2G/3G)"
;;
*)
SIGNAL_TYPE="UNKNOWN"
;;
esac



# Set Network Type Mode
case $SERVICE_MODE in
5)
SIGNAL_TYPE="WCMDA/UMTS (3G)"
;;
3)
SIGNAL_TYPE="GSM/GPRS (2G)"
;;
*)
SIGNAL_TYPE="UNKNOWN"
;;
esac


clear
# Play sound if exit status =0 i.e. PPP connected
if [ "$PPP_EXIT_STATUS" = "0" ];
then

# Notify that network is available
if [ "x$AVAILABLE_NETWORK" != "x" ];
then
echo "`date +"%b %d at %I:%M:%S"`
---
So far so good: Connected to the following [$ISP] network ...

$AVAILABLE_NETWORK
"
fi



# Remove all stuff below
echo "`date +"%b %d at %I:%M:%S"`
---
Checking for outside connectivity i.e. DNS ...
"
# Wait for PPP to settle
sleep 10

else
# Echo Exit Status and Signal Strength
echo "`date +"%b %d at %I:%M:%S"` (Attempt #$PPPD_RUN)
---  
Error: $PPP_ERROR_MSG"

# Notify that network is NOT available
if [ "x$AVAILABLE_NETWORK" = "x" ];
then
echo "`date +"%b %d at %I:%M:%S"`
---
Error: There's no $ISP network available, please try another network type
"
#exit 1

fi

# Connection failed - Wait for 1 minute
echo "
Will attempt to connect again in 1 minute ...
"

# Wait for PPP to settle
sleep 60

fi

# Retry Host
dig_host
let "PPPD_RUN = $PPPD_RUN + 1"
done



# CONNECTED
# ---------
# Check status of ppp device
ifconfig $PPP_INTERFACE > /dev/null 2>&1
PPP_DEV_ACTIVE=`echo $?`
# Wait until PPP Device is active to proceed to iptables masquerading rules
until [ "$PPP_DEV_ACTIVE" = "0" ]
do
echo "Waiting for $PPP_INTERFACE to be activated"
sleep 1
ifconfig $PPP_INTERFACE > /dev/null 2>&1
PPP_DEV_ACTIVE=`echo $?`
done


# Connection succeeded - alert
mplayer /usr/share/sounds/KDE_Startup_2.ogg > /dev/null 2>&1


# QUERY Modem when in On-Line state
# ---------------------------------
# Remove stats file if it exists, by creating new file with time stamp
echo "$DATE_TIMESTAMP
---" > $DSFLOWRPT_STATS_FILE

# Get connection speed stats
cat $MODEMCONTROLDEV >> $DSFLOWRPT_STATS_FILE 2>&1 &
sleep 2
grep DSFLOWRPT $DSFLOWRPT_STATS_FILE > /dev/null 2>&1
DSFLOWRPT_EXIT=$?
STATS_COUNT=1
while [ "$DSFLOWRPT_EXIT" != "0" ] && [ "$STATS_COUNT" -le "15" ];
do
echo "[$STATS_COUNT] Querying network traffic statistics ...
"
sleep 1
grep DSFLOWRPT $DSFLOWRPT_STATS_FILE > /dev/null 2>&1
let "STATS_COUNT = $STATS_COUNT + 1"
done

# Generate Hex values file for dsflowrpt parameters
grep DSFLOWRPT $DSFLOWRPT_STATS_FILE | tail -1 > $DSFLOWRPT_HEX_TMP_FILE


# DSFLOWRPT variables
# -------------------
# The duration of the connection in seconds
CURR_DS_TIME_HEX=`cat $DSFLOWRPT_HEX_TMP_FILE | cut -d "," -f1 | cut -d ":" -f2`
CURR_DS_TIME=`echo "ibase=16;$CURR_DS_TIME_HEX" | bc`

# The transmit (upload) speed in bytes per second (n*8 / 1000 = kbps)
TX_RATE_HEX=`cat $DSFLOWRPT_HEX_TMP_FILE | cut -d "," -f2`
TX_RATE=`echo "ibase=16;$TX_RATE_HEX" | bc`

# The receive (download) speed in bytes per second (n*8 / 1000 = kbps)
RX_RATE_HEX=`cat $DSFLOWRPT_HEX_TMP_FILE | cut -d "," -f3`
RX_RATE=`echo "ibase=16;$RX_RATE_HEX" | bc`

# The total bytes transmitted during this session
CURR_TX_FLOW_HEX=`cat $DSFLOWRPT_HEX_TMP_FILE | cut -d "," -f4`
CURR_TX_FLOW=`echo "ibase=16;$CURR_TX_FLOW_HEX" | bc`

# The total bytes received during this session
CURR_RX_FLOW_HEX=`cat $DSFLOWRPT_HEX_TMP_FILE | cut -d "," -f5`
CURR_RX_FLOW=`echo "ibase=16;$CURR_RX_FLOW_HEX" | bc`

# PDP connection transmitting rate determined after negotiating with the 
# network side, unit: Bps.
QOS_TX_RATE_HEX=`cat $DSFLOWRPT_HEX_TMP_FILE | cut -d "," -f6`
QOS_TX_RATE=`echo "ibase=16;$QOS_TX_RATE_HEX" | bc`

# PDP connection receiving rate determined after negotiating with the 
# network side, unit: Bps.
QOS_RX_RATE_HEX=`cat $DSFLOWRPT_HEX_TMP_FILE | cut -d "," -f7`
QOS_RX_RATE=`echo "ibase=16;$QOS_RX_RATE_HEX" | bc`



# Print banner
clear
echo "    =======================================================================
    `date +'%b %d at %I:%M:%S'`	Success! You are now fully connected ...
    =======================================================================
		Active Network 	     =  $AVAILABLE_NETWORK
		Signal Type 	     =  $SIGNAL_TYPE
		Signal Strength	     =  $SIGNAL_QUALITY
		PPP CHAP Server      =  $REMOTE_CHAP_SERVER
		Local IP Address     =  $LOCAL_IP_ADDRESS
		Remote IP Address    =  $REMOTE_IP_ADDRESS
		Primary DNS Server   =  $PRIMARY_DNS_ADDRESS
		Secondary DNS Server =  $SECONDARY_DNS_ADDRESS
		PPP Adaptor    	     =  $PPP_INTERFACE
		Remote MTU	     =  $REMOTE_MTU
		---------------------------------------------
		Connection speed details after [$CURR_DS_TIME] Seconds:
		---------------------------------------------
		TX_RATE		     =	$TX_RATE bps
		RX_RATE		     =	$RX_RATE bps
		CURR_TX_FLOW	     =	$CURR_TX_FLOW b
		CURR_RX_FLOW	     =	$CURR_RX_FLOW b
		QOS_TX_RATE	     =	$QOS_TX_RATE Bps
		QOS_RX_RATE	     =	$QOS_RX_RATE Bps
    ======================================================================="