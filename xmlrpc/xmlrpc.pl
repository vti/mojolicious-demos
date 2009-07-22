#!/usr/bin/perl

use strict;
use warnings;

use FindBin;

use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../../lib";

use Mojo::Transaction;
use Mojo::Client;
use Mojo::Parameters;

use Protocol::XMLRPC;
use Data::Dumper;

my $method = shift;
my @params = @ARGV;

die 'xmlrpc: <operator> <param1> <param1>' unless $method;

my $xmlrpc = Protocol::XMLRPC->new(
    http_req_cb => sub {
        my ($self, $url, $method, $headers, $body, $cb) = @_;

        my $tx = Mojo::Transaction->new;
        $tx->req->method($method);
        $tx->req->url->parse($url);

        $tx->req->headers->header('User-Agent' => 'Mojo');
        foreach my $header (keys %$headers) {
            $tx->req->headers->header($header => $headers->{$header});
        }

        $tx->req->body($body);

        #warn $tx->req;

        my $client = Mojo::Client->new;
        $client->process_all($tx);

        $headers = {};

        foreach my $header (@{$tx->res->headers->names}) {
            $headers->{$header} = $tx->res->headers->header($header);
        }

        #warn $tx->res;

        $cb->($self, $tx->res->code, $headers, $tx->res->content->file->slurp);
    }
);

$xmlrpc->call(
    'http://localhost:3000' => $method => [@params] => sub {
        my ($self, $method_response) = @_;

        if (!$method_response) {
            print "internal error\n";
        }
        elsif ($method_response->fault) {
            print 'error: ', $method_response->fault_string, "\n";
        }
        else {
            print $method_response->param->value, "\n";
        }
    }
);
