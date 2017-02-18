use common::sense;
use Test::More;
use Test::Exception;
use Plack::Test;
use HTTP::Request::Common;
use Path::Tiny;
use Plack::Util;
use Enigma;

get '/foo' => sub {
    my $c = shift;
    isa_ok $c, 'Amon2::Web';
    can_ok $c, 'validate';
    can_ok $c, 'render_json_with_code';
    can_ok $c, 'render_json';
    can_ok $c, 'render_text';

    return $c->render_text('ok');
};
my $app = __PACKAGE__->to_app;

subtest 'basic' => sub {
    test_psgi
        app => $app,
        client => sub {
            my $cb  = shift;
            # my $res = $cb->(GET '/foo');
            my $req = HTTP::Request->new(GET => "/foo");
            my $res = $cb->($req);
            is $res->code, 200;
            is $res->content, 'ok';
        };
};

# TODO JSON を受け付けられるかどうか

# subtest 'validation' => sub {
#     ok 1;
# };

done_testing;
