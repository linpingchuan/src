# The TLS server closes the connection to syslogd.
# The client writes a message to Sys::Syslog native method.
# The syslogd writes it into a file and through a pipe.
# The syslogd passes it via IPv4 TLS to an explicit loghost.
# The server receives the message on its TLS socket.
# Find the message in client, pipe, syslogd log.
# Check that syslogd writes a log message about the server close.

use strict;
use warnings;
use Socket;

our %args = (
    client => {
	func => sub {
	    my $self = shift;
	    ${$self->{syslogd}}->loggrep("loghost .* connection close", 5)
		or die "no connection close in syslogd.log";
	    write_log($self);
	},
    },
    syslogd => {
	loghost => '@tls://127.0.0.1:$connectport',
	loggrep => {
	    qr/Logging to FORWTLS \@tls:\/\/127.0.0.1:\d+/ => '>=4',
	    get_testgrep() => 1,
	    qr/syslogd\[\d+\]: loghost .* connection close/ => 1,
	},
    },
    server => {
	listen => { domain => AF_INET, proto => "tls", addr => "127.0.0.1" },
	func => sub {
	    my $self = shift;
	    shutdown(\*STDOUT, 1)
		or die "shutdown write failed: $!";
	    ${$self->{syslogd}}->loggrep("loghost .* connection close", 5)
		or die "no connection close in syslogd.log";
	},
	loggrep => {},
    },
    file => {
	loggrep => {
	    qr/syslogd\[\d+\]: loghost .* connection close/ => 1,
	},
    },
);

1;
