#!/usr/bin/env perl

use Mojolicious::Lite;
use Mojo::Date;
use Pod::Simple::HTML;

my %config = (
    name        => 'vti',
    email       => 'viacheslav.t@gmail.com',
    title       => 'vti\'s notes',
    description => 'different thoughts'
);

get '/:index' => {index => 'index'} => 'index' => sub {
    my $c = shift;

    my $root = $c->app->home->rel_dir('articles');

    opendir DIR, $root or return $c->app->static->serve_404($c);
    my @files = grep { -r "$root/$_" && m/\.pod$/ } readdir(DIR);
    closedir DIR;

    my @articles;
    foreach my $file (@files) {
        my $data = _parse_article("$root/$file");
        next unless $data;

        my ($name) = ($file =~ m/^(.*?)\.pod/);

        push @articles,
          { name  => $name,
            mtime => Mojo::Date->new((stat("$root/$file"))[9]),
            %$data
          };
    }

    @articles = sort { $b->{mtime}->epoch <=> $a->{mtime}->epoch } @articles;

    my $last_modified = $articles[0]->{mtime};

    return 1 unless _is_modified($c, $last_modified);

    $c->stash(articles => \@articles, config => \%config);

    $c->res->headers->header('Last-Modified' => $last_modified);
};

get '/articles/:file' => 'article' => sub {
    my $c = shift;

    my $root = $c->app->home->rel_dir('articles');
    my $path = "$root/" . $c->stash('file') . '.pod';
    my $last_modified = Mojo::Date->new((stat($path))[9]);

    return $c->app->static->serve_404($c) unless -r $path;

    my $data; $data = _parse_article($path)
        or return $c->app->static->serve_404($c);

    return 1 unless _is_modified($c, $last_modified);

    $c->stash(article => $data, template => 'article', config => \%config);

    $c->res->headers->header('Last-Modified' => Mojo::Date->new($last_modified));
};

sub _is_modified {
    my $c = shift;
    my ($last_modified) = @_;

    my $date = $c->req->headers->header('If-Modified-Since');
    return 1 unless $date;

    return 1 unless Mojo::Date->new($date)->epoch == $last_modified->epoch;

    $c->res->code(304);

    return 0;
}

my %_articles;

sub _parse_article {
    my $path = shift;

    return $_articles{$path} if $_articles{$path};

    my $parser = Pod::Simple::HTML->new;

    $parser->force_title('');
    $parser->html_header_before_title('');
    $parser->html_header_after_title('');
    $parser->html_footer('');

    my $title = '';
    my $content = '';;

    $parser->output_string(\$content);
    eval { $parser->parse_file($path) };
    return if $@;

    $title = $parser->get_title;

    return $_articles{$path} = {title => $title, content => $content};
}

app->types->type(rss => 'application/rss+xml');

shagadelic;
__DATA__

@@ index.html.eplite
% my $self = shift;
% $self->stash(layout => 'wrapper');
% my $articles = $self->stash('articles');
<h1>Articles</h1>
<ul>
% foreach my $article (@$articles) {
    <li><a href="/articles/<%== $article->{name} %>.html"><%= $article->{title} || $article->{name} %></a>
    Last modified: <%= $article->{mtime} %></li>
% }
</ul>

@@ index.rss.eplite
% my $self = shift;
% my $articles = $self->stash('articles');
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xml:base="<%= $self->req->url->base %>"
    xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title><%= $self->stash('config')->{title} %></title>
        <link><%= $self->req->url->base %></link>
        <description><%= $self->stash('config')->{description} %></description>
        <pubDate><%= $articles->[0]->{mtime} %></pubDate>
        <lastBuildDate><%= $articles->[0]->{mtime} %></lastBuildDate>
        <generator>Mojolicious::Lite</generator>
    </channel>
% foreach my $article (@$articles) {
% my $link = $self->url_for('article', article => $article->{name}, format => 'html')->to_abs;
    <item>
      <title><%== $article->{title} %></title>
      <link><%= $link %></link>
      <description><%== $article->{content} %></description>
      <pubDate><%= $article->{mtime} %></pubDate>
      <guid><%= $link %></guid>
    </item>
% }
</rss>

@@ article.html.eplite
% my $self = shift;
% $self->stash(layout => 'wrapper');
% my $article = $self->stash('article');
<%= $article->{content} %>

@@ layouts/wrapper.html.eplite
% my $self = shift;
% my $config = $self->stash('config');
<!html>
    <head><title><%= $config->{title} %></title></head>
    <body>
        <div><a href="/">Articles</a></div>

        <%= $self->render_inner %>

        <div><small>Powered by Mojolicious::Lite & Pod::Simple::HTML</small></div>
    </body>
</html>
