#!/usr/bin/perl
# A demo application for sharing files :)

use Mojolicious::Lite;

my $dir = shift;

die 'usage: <dir>' unless $dir && -d $dir;

get '/(*cwd)' => sub {
    my $c = shift;

    my $cwd = $c->stash('cwd') || '';
    $cwd = '/' . $cwd if $cwd;
    $cwd =~ s/\/$//;

    my $abs = $cwd ne '/' ? $c->app->static->root . $cwd : $c->app->static->root;

    opendir DIR, $abs or return $c->app->static->serve_404($c);
    my @files = grep { -r "$abs/$_" && !m/^\./ } readdir(DIR);
    @files = map {
        {   name   => -d "$abs/$_" ? "$_/"     : $_,
            path   => $cwd         ? "$cwd/$_" : "/$_",
            size   => -s "$abs/$_",
            is_dir => -d "$abs/$_" ? 1         : 0
        }
    } @files;
    closedir DIR;

    $c->stash(cwd => $cwd, files => \@files);
} => 'root';

app->static->root($dir);

shagadelic('daemon');

__DATA__

@@ root.html.epl
% my $self = shift;
% my $files = $self->stash('files');
% my $cwd = $self->stash('cwd') || '';
<%= $cwd || '/' %>
<ul>
% if ($cwd) {
<li><a href="<%= "$cwd/../" %>">..</a></li>
% }
% foreach my $file (@$files) {
<li><%= $file->{size} %> <a href="<%= $file->{path} %>"> <%= $file->{name} %></a></li>
% }
</ul>
