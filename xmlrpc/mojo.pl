#!/usr/bin/env perl

use strict;
use warnings;

$ENV{MOJO_APP} = 'XMLRPC';

use Mojolicious::Scripts;

Mojolicious::Scripts->new->run(@ARGV);

# The application class
package XMLRPC;

use strict;
use warnings;

use base 'Mojolicious';

sub startup {
    my $self = shift;

    $self->log->level('fatal');

    $self->routes->route('/')->to(controller => 'method', action => 'process');
}

# A controller class
package XMLRPC::Method;

use strict;
use warnings;

use base 'Mojolicious::Controller';

use Protocol::XMLRPC::Dispatcher;

sub process {
    my $self = shift;
    my $c = $self->ctx;

    return $c->res->body('Only POST requests are allowed')
      unless $c->req->method eq 'POST';

    my $dispatcher = Protocol::XMLRPC::Dispatcher->new(
        methods => {
            plus => {
                args    => [qw/integer integer/],
                handler => sub { $_[0]->value + $_[1]->value; }
            },
            minus => {
                args    => [qw/integer integer/],
                handler => sub { $_[0]->value - $_[1]->value; }
            }
        }
    );

    $dispatcher->dispatch(
        $c->req->body => sub {
            $c->res->headers->content_type('text/xml');
            $c->res->body(shift);
        }
    );
}

