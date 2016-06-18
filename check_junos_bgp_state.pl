#! /usr/bin/perl
# nagios: +epn
# Check BGP State(Simple) - nagios plugin
# verifies thet BGP connections are established
# If not, and enabled,  CRITICAL alarm will be triggered
#
# Hardcoded for SNMP version 2c for now.
#
# by bjorn@frostberg.net (and some copy paste from other scripts)
#
#Example syntax:
#
#./check_junos_bgp_state.pl -H 10.10.10.10 -C public
#
#Checking an IPv6 only router might work with the -d parameter.
#
#Example(not tested):
#
#check_junos_bgp_state.pl -H <ipv6 address> -C public -d udp/ipv6

use strict;
use warnings;

use Net::SNMP qw(:snmp);
use Getopt::Long;
&Getopt::Long::config('auto_abbrev');
use Net::IP;


my $version = "0.1";
my $TIMEOUT = 10;
my $snmp_domain="udp/ipv4";
my $snmp_version="v2c";
# default return value is UNKNOWN
my $state = "UNKNOWN";
my $status;
my $needhelp;
my $answer;
my $output;
my $output_OK;
my $session;
my $error;


my %ERRORS = (
        'OK'       => '0',
        'WARNING'  => '1',
        'CRITICAL' => '2',
        'UNKNOWN'  => '3',
);

# external variable declarations
my $hostname;
my $community = "public";
my $port = 161;

# OID definitions
my $bgp_peer_state_oid = '1.3.6.1.4.1.2636.5.1.1.2.1.1.1.2';
my $bgp_peer_admin_status_oid = '1.3.6.1.4.1.2636.5.1.1.2.1.1.1.3';
#BGP states
my @bgp_peer_state_text       = ("None","Idle","Connect","Active","Opensent","Openconfirm","Established");
my @bgp_peer_state            = (0,1,2,3,4,5,6);

# Just in case of problems, let's not hang NAGIOS
$SIG{'ALRM'} = sub {
        print ("UNKNOWN: No snmp response from $hostname\n");
        exit $ERRORS{"UNKNOWN"};
};
alarm($TIMEOUT);

# we must have -some- arguments
if (scalar(@ARGV) == 0) {
        usage();
} # end if no options

Getopt::Long::Configure("no_ignore_case");
$status = GetOptions(
        "h|help"             => \$needhelp,
        "C|snmpcommunity=s"  => \$community,
        "p|port=i"           => \$port,
        "H|hostip=s"       => \$hostname,
        "d|snmpdomain=s"       => \$snmp_domain,
);

if ($status == 0 || $needhelp) {
        usage();
} # end if getting options fails or the user wants help

if (!defined($hostname)) {
        $state = "UNKNOWN";
        $answer = "Host IP must be specified";
        print "$state: $answer\n";
        exit $ERRORS{$state};
} # end check for host IP

#Define SNMP session
 ($session, $error) = Net::SNMP->session(
   -domain      => $snmp_domain,
   -hostname    => shift || $hostname,
   -community   => shift || $community,
   -nonblocking => 0,
   -translate   => [-octetstring => 0],
   -version     => $snmp_version,
);

my $critical = "";
my $OK = "";
my @octets;

# Do the SNMP queries
my $result_bgp_state = $session->get_table(Baseoid => $bgp_peer_state_oid );
my $result_bgp_admin_status = $session->get_table(Baseoid => $bgp_peer_admin_status_oid );
# Check if we got anything back
if ( !defined($result_bgp_state) || !defined($result_bgp_admin_status) ) {
	# If no such OID exists
	$session->close;
	print "BGP Not Configured : OK\n";
	exit $ERRORS{"OK"};
#	printf("ERROR: netsnmp : %s.\n", $session->error);
#	exit $ERRORS{"UNKNOWN"};
}
# Loop through BGP admin status
my $i=0;
my @bgp_admin_status;
foreach my $key1 ( sort (keys %$result_bgp_admin_status)) {
	$bgp_admin_status[$i] = $$result_bgp_admin_status{$key1};
#	print $bgp_admin_status[$i];
	$i++;
}
	


$i=0;
my $peer_ip;
my $hex;
my $establised_bgp_peers=0;
foreach my $key ( sort(keys %$result_bgp_state)) {
	@octets=split (/\./,$key);
	#check if it's IPv6 peer
	if ( scalar(@octets) > 26 ) {
		my @octets_hex;
		foreach my $dec (@octets) {
			$hex = sprintf ("%lx", $dec);
			if ( length($hex) < 2 ) {
				$hex= 0 . $hex;
			}
			push(@octets_hex,$hex);
		}
		$peer_ip = "$octets_hex[34]$octets_hex[35]:$octets_hex[36]$octets_hex[37]";
		$peer_ip .= ":$octets_hex[38]$octets_hex[39]:$octets_hex[40]$octets_hex[41]";
		$peer_ip .= ":$octets_hex[42]$octets_hex[43]:$octets_hex[44]$octets_hex[45]";
		$peer_ip .= ":$octets_hex[46]$octets_hex[47]:$octets_hex[48]$octets_hex[49]";
		$peer_ip = Net::IP::ip_compress_address($peer_ip, 6);
	}
	else {
		$peer_ip = "$octets[22].$octets[23].$octets[24].$octets[25]";
	}
#	print "$peer_ip\n";
#	print $$result_bgp_state{$key};
	# Check if state is Established
	if ( ($$result_bgp_state{$key}) lt 6) {
		# Check if manually shutdown/disabled
		if ( $bgp_admin_status[$i] eq "1" ) {
	        	$OK="yes";
                	$output_OK .= "Peer: $peer_ip";
                	$output_OK .= "Shutdown\n";
		}
		# Not manually shutdown/disabled
		else {	
			$critical = "yes";
                	$output .= "Peer: $peer_ip ";
                	$output .= "$bgp_peer_state_text[$$result_bgp_state{$key}] ";
		}

	}
	else {
		$establised_bgp_peers++;
	        $OK="yes";
                $output_OK .= "Peer: $peer_ip ";
                $output_OK .= "$bgp_peer_state_text[$$result_bgp_state{$key}]\n";

	}
	$i++;		
}
$session->close;

# Print the results

if ($critical eq "yes") {
        print $output," : CRITICAL | bgp_peers=$establised_bgp_peers\n";
        exit $ERRORS{"CRITICAL"};
}

if ($OK eq "yes") {
        print "All enabled BGP Neighbors are in Established state | bgp_peers=$establised_bgp_peers\n";
	print $output_OK;
        exit $ERRORS{"OK"};
}


# the usage of this program
sub usage
{
        print <<END;
== check_junos_bgp_state.pl v$version ==
Perl Juniper JunOS SNMP BGP status check plugin for Nagios

Usage:
  check_junos_bgp_state.pl (-C|--snmpcommunity) <read_community>
                     (-H|--host IP address) <host ip>
                     [-p|--port] <port>
                     [-d|--snmp-domain] <udp/ipv4>

END
        exit $ERRORS{"UNKNOWN"};
}

