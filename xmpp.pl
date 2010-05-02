#!/usr/bin/perl

use Mojo::IOLoop;

use strict;
use warnings;

my $loop = Mojo::IOLoop->singleton;

my ($from, $password, $to, $message) = @ARGV;

die 'usage: echo <from> <password> <to> <message>'
  unless $from && $password && $to && $message;

my ($username, $host) = split('@', $from);
my $port = 5222;

my $buffer = [];

push @$buffer, <<"EOF";
<?xml version='1.0'?>
   <stream:stream
       to='$host'
       xmlns='jabber:client'
       xmlns:stream='http://etherx.jabber.org/streams'
       version='1.0'>
EOF

push @$buffer, <<"EOF";
    <iq type='set' id='auth'>
    <query xmlns='jabber:iq:auth'>
    <username>$username</username>
    <password>$password</password>
    <resource>mojo</resource></query></iq>
EOF

push @$buffer, <<"EOF";
    <presence to='$to'>
       <priority>8</priority>
    </presence>
    <message to='$to' type='chat'>
        <subject></subject>
        <body>$message</body>
    </message>
</stream:stream>
EOF

my $server = $loop->connect(
    address => $host,
    port    => $port,
    cb      => sub {
        warn "Connected to $host:$port";

        $loop->writing($_[1]) if length $buffer;
    }
);

$loop->read_cb(
    $server => sub {
        $loop->writing($server);
    }
);

$loop->write_cb(
    $server => sub {
        $loop->not_writing($server);
        my $message = shift @$buffer;
        if ($message) {
            return $message;
        }
    }
);

$loop->connection_timeout($server => 600);

$loop->error_cb(
    $server => sub {
        warn "Disconnected from $host (connection error)";
        return;
    }
);

$loop->hup_cb(
    $server => sub {
        warn "Disconnected from $host (hangup)";
        return;
    }
);

$loop->start;
