#!/usr/bin/env perl
use common::sense;
use Enigma;

get '/' => sub {
    my $c = shift;
    return $c->render_json({ok => \1});
};
__PACKAGE__->to_app;
