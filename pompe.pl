#!/usr/bin/perl -w
# activate / deactivate pin
# doesn't handle the port type (relay) as the arduino take care of it
# when the arduino starts, all pin are low but for relay they're high

use strict;
use warnings;
use Device::SerialPort;
use Config::Simple;

my $debug = 0;

$SIG{'INT'} = \&signal_handler;
$SIG{'TERM'} = \&signal_handler;

my $cfg = new Config::Simple("/etc/arduino.cfg") or die_cleanly(Config::Simple->error());
my $portName = $cfg->param('tty');
die_cleanly("port not defined") unless (defined $portName);

my $url = $cfg->param('url');

# Set up the serial port
# 19200, 81N on the USB ftdi driver
my $port = Device::SerialPort->new($portName) || die_cleanly("Can't open $portName: $!");
$port->databits(8);
$port->baudrate(9600);
$port->parity("none");
$port->stopbits(1);


# workaround : few iteration are made if needed, sometimes, the status doesn't get well transmit
# the begin or end is missing, so asking it again seems to solve the problem.
my $cpt = 0;
my $st = "";
my $prev = 0;
while ( 1 ) {
	my $byte = $port->read(1);
	if ($byte eq "") {
		next;
	}
# \n reached ?
	if ( ord $byte ==  '10') { 
		if ($st =~ m/^-- (.*)$/) {
			if ($prev != $1) {
				my $val = $1 - $prev;
				$prev = $1;
				print "nouvelle valeur $val $prev \n";
				exec_cmd("curl -X POST -d $val $url");
			}
		}
		$st = "";
	} else {
		$st .= $byte;
	}
}

exit_cleanly(0);

#####################
# log debug
sub log_debug {
	my $msg = shift;
	print "$msg\n" unless (!$debug);
}

#####################
# empty the serial buffer by reading all data available
sub empty_serial_buffer {
	my $cpt = 0;
	while ($cpt < 200) {
		$port->lookfor;
		$cpt++;
	}
}

#####################
# execute the specified command 
# exit cleanly if something wrong happened
# @param $cmd : command to execute
sub exec_cmd {
	my $cmd = shift;
	log_debug("cmd : $cmd");
	system( $cmd );
}

#####################
# Print an error message, delete temp file, close the connection to the
# database, remove the lock if it exits and exit
# @param $msg : error to display
sub die_cleanly {
	my $msg = shift;
	printf("### ERROR : $msg\n");
	exit_cleanly(1);
}

#####################
# Delete temp file, close the connection to the database, remove the lock if it
# exits and exit with the specified code
# @param $exit_status : exit code
sub exit_cleanly {
	my $exit_status = shift;

	$port->close if (defined $port);

	if ($exit_status == 0) {
		log_debug("#### Finished ####");
	}
	exit($exit_status);
}

#####################
# signal handler
sub signal_handler {
	my $signame = shift;
	die_cleanly("Signal [$signame] catched");
}


