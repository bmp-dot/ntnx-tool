#!/bin/bash

#description	:Nutanix Deployment Toolbox for Nutanix SE use only
#author		:Ben Peterson bpeterson@nutanix.com
#updated	:2017-01-10
#version	:0.6    
#notes		:


#IPMI define current password
SMCOLD=ADMIN
#IPMI define New Password
SMCNEW=ADMIN

#Variables not defined for ESX or CVM password and are set static below 



clear
selection=
until [ "$selection" = "e" ]; do

echo -e "\033[32m"
echo ""
echo  "Nutanix Deployment Toolbox"
echo "1 - Change all IPMI Passwords in Nutanix Cluster"
echo "2 - Change all ESXi Passwords in Nutanix Cluster"
echo "3 - Change all CVM  Passwords in Nutanix Cluster"
echo "4 - Set UseDNS option to no on all ESX hosts"
echo "5 - Change CVM Network VLAN tags - Stop cluster first!" 
echo "6 - Change ESX Management VLAN tags - Connection will be lost in 30 seconds!"
echo "9 - List ESX VLAN tags"
echo ""
echo ""
echo "e - Exit Utility"
echo ""
echo -n "Enter Selection: "
read selection
echo ""
case $selection in
       
1 ) 
#Define function to generate list of IPMI IPs
ntnx-smcip(){
ncli host list | grep -w "IPMI Address" | awk {'print $4'};
}
#Define function generate list of Host IDs
ntnx-hostid(){
ncli host list | grep -w "ID" | awk {'print $3'};
}
#read -p "Enter current IPMI password: " SMCOLD;
#read -p "Verify current IPMI password: " SMCOLD2;
#while [ "SMCOLD" != "$SMCOLD2" ]; do 
#read -p "Password missmatch, try again:" SMCOLD2;
#read -p "Enter new IPMI password: " SMCNEW;

#Use IPMI tool to change password
#The "Close Session command failed" output is expected after change completes
for s in `ntnx-smcip`; do ipmitool -H $s -I lanplus -U ADMIN -P $SMCOLD user set password 2 $SMCNEW; done
#Update zeus config with new password
for h in `ntnx-hostid`; do ncli host edit id=$h ipmi-password=$SMCNEW; done ;;



2 ) 
#Change all ESX passwords in Nutanix cluster for the user root 
#First define a variable that will establish an SSH session as the root user
#When the SSH connection is establsihed an echo command is run that updates the passwords
for e in `hostips`; do echo ESX host $e && ssh root@$e 'echo "nutanix/4u" | passwd --stdin'; done ;;
        

3 ) 
#Change all CVM passwords in Nutanix cluster for the user nutanix
#First define a variable that will establish an SSH session as the nutanix user
#When the SSH connection is establsihed an echo command is run that updates the passwords
#Note sudo is used here because only root is allowed to run the command. 
for c in `svmips`; do echo CVM $c && ssh $c 'echo "nutanix/4u" | sudo passwd --stdin nutanix';done ;;


4)
#First define a variable that will establish an SSH session as the root user
#When the SSH connection is establsihed an echo command is run that updates the SSHD conf file
for i in `hostips`; do echo "Changing sshd_config on $i" && ssh root@$i 'echo "useDNS no" >> /etc/ssh/sshd_config';done ;;


5)
read -p "Enter new CVM VLAN Network tag: " CVMVLAN; 
for i in `hostips`; do echo "Changing CVM VLAN Network tag on $i to $CVMVLAN" && ssh -f root@$i "nohup sleep 600 && esxcfg-vswitch -p 'VM Network' -v '$CVMVLAN' vSwitch0";done ;;


6)
read -p "Enter new ESX Management VLAN tag: " MGMTVLAN;
for i  in `hostips`; do echo "Changing ESX Management VLAN tag on $i to $MGMTVLAN" && ssh -f root@$i "nohup sleep 600 && esxcfg-vswitch -p 'Management Network' -v '$MGMTVLAN' vSwitch0";done ;;


9)
for i in `hostips`; do echo "Displaying VLANs on $i" && ssh root@$i "esxcfg-vswitch -l | grep 'VM Network' -B1 -A1";done ;;


e ) 
echo -e "\033[0m" 
clear
exit ;;
        * ) echo "Please select option"
        esac
done
