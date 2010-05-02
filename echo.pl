#!/usr/bin/perl

# Mojolicious echo server

use Mojo::IOLoop;

use strict;
use warnings;

my $loop = Mojo::IOLoop->singleton;

my ($host, $port) = @ARGV;

die 'usage: echo <host> <port>' unless $host && $port;

my $buffer = "";

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
        $buffer = $_[2];
        $loop->writing($server);
    }
);

$loop->write_cb(
    $server => sub {
        $loop->not_writing($server);
        return $buffer;
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
