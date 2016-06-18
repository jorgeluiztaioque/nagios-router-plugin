
   	     		NAGIOS PLUGINS

-------------------------------------------------------------------------------

Description:
------------

The IU Nagios Plugins are a set of service checks for the Nagios monitoring 
system (http://www.nagios.org).  This set of plugins will check the 
availability of a variety of services on your network devices.

License:
--------

The IU Nagios Plugins are licensed under the IU Open Source license, a 
BSD-style license.  Please see 'LICENSE' in this directory for a complete 
copy of the licensing agreement.

Requirements:
-------------
Perl
NET::SNMP
Getopt::Std
Working Nagios installation

Included Plugins:
-----------------

check_cpu:  Checks via SNMP the CPU load on Cisco or Juniper equipment.

check_bgp: Checks via SNMP the status of a BGP session

check_isis: Checks via SNMP the ISIS adjacency of a router

check_ospf: Checks via SNMP the OSPF status from the OSPF neighbor table

check_pim: Checks via SNMP the status of a PIM neighbor

check_msdp: Checks via SNMP the status of a MSDP peering session

check_intf: Checks via SNMP the status of an interface, given an IP address 
associated with that interface

check_intf_by_ifname: Checks via SNMP the status of an interface given the 
interface name associated with the interface.

Usage:
------

These plugins require a working Nagios install, and behave in the standard 
manner for Nagios plugins.  To get usage instructions for each plugin, run 
the plugin with no parameters e.g.:

[root@trails Nagios-Plugins]# ./check_bgp 

usage:  ./check_bgp [-h] -r <hostname> -c <community> -n <neighbors> 

[-h]            :       Print this message
[-r] <router>   :       IP Address or Hostname of the router
[-c] <community>:       SNMP Community String  (default = "public")
[-n] <neighbors>:       % delimited list of neighbor ip addresses 
                        and descriptions.   Example:  10.10.10.1%ROUTER_A


------------------------
 THE FIRST IS CREATED BY INDIANA UNIVERSITY GLOBAL NETWORK OPERATIONS CENTER

