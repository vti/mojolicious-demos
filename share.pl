#!/usr/bin/perl
# A demo application for sharing files :)

use FindBin;

use lib "$FindBin::Bin/../lib";

my $dir = shift;

die 'usage: <dir>' unless $dir && -d $dir;

use Mojolicious::Lite;

get '/(*cwd)' => 'root' => sub {
    my $c = shift;
    #my $c = $self->ctx;

    my $cwd = $c->stash('cwd') || '';
    $cwd = '/' . $cwd if $cwd;
    $cwd =~ s/\/$//;

    my $abs = $cwd ne '/' ? $c->app->static->root . $cwd : $c->app->static->root;

    opendir DIR, $abs or return $c->app->static->serve_404($c);
    @files = grep { -r "$abs/$_" && !m/^\./ } readdir(DIR);
    @files = map {
        {   name   => -d "$abs/$_" ? "$_/"     : $_,
            path   => $cwd         ? "$cwd/$_" : "/$_",
            size   => -s "$abs/$_",
            is_dir => -d "$abs/$_" ? 1         : 0
        }
    } @files;
    closedir DIR;

    $c->stash(cwd => $cwd, files => \@files);
};

app->static->root($dir);

@ARGV = 'daemon';
shagadelic;

__DATA__
__root.html.eplite__
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
