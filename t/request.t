use common::sense;
use Test::More;
use Test::Exception;
use Plack::Test;
use HTTP::Request::Common;
use Enigma;
use JSON;

get '/basic' => sub {
    my $c = shift;
    isa_ok $c, 'Amon2::Web';
    can_ok $c, 'render_json_with_code';
    can_ok $c, 'render_json';
    can_ok $c, 'render_text';
    can_ok $c, 'validate';

    return $c->render_text('OK');
};
any '/validate' => sub {
    my ($c) = @_;
    my $p = $c->validate(
        foo => 'Str',
    ) or return $c->error_res;
    return $c->render_text('OK');
};
get '/users/{id}' => sub {
    my ($c) = @_;
    my $p = $c->validate(
        id => 'Int|ArrayRef[Int]',
    ) or return $c->error_res;
    return $c->render_text('OK');
};
my $app = __PACKAGE__->to_app;

subtest 'basic' => sub {
    test_psgi
        app => $app,
        client => sub {
            my $cb  = shift;
            my $res = $cb->(GET '/basic');
            is($res->code, 200) or note $res->content;
            is $res->content, 'OK';
            is $res->headers->header('Cache-Control'), 'no-cache';
        };
};

subtest 'validation' => sub {
    test_psgi
        app => $app,
        client => sub {
            my $cb  = shift;
            subtest 'GET' => sub {
                {
                    my $res = $cb->(GET '/validate?foo=bar');
                    is($res->code, 200) or note $res->content;
                }
                {
                    my $res = $cb->(GET '/validate');
                    is($res->code, 400) or note $res->content;
                }
            };
            subtest 'POST' => sub {
                {
                    my $res = $cb->(POST '/validate', [foo => 'bar']);
                    is($res->code, 200) or note $res->content;
                }
                {
                    my $res = $cb->(POST '/validate',
                                    'Content-Type' => 'application/json',
                                    Content => encode_json { foo => 'bar' });
                    is($res->code, 200) or note $res->content;
                }
                {
                    my $res = $cb->(POST '/validate');
                    is($res->code, 400) or note $res->content;
                }
            };
        };
};

subtest 'path parameters' => sub {
    test_psgi
        app => $app,
        client => sub {
            my $cb  = shift;
            {
                my $res = $cb->(GET '/users/1');
                is($res->code, 200) or note $res->content;
            }
            SKIP: {
                skip 'not implemented yet';
                my $res = $cb->(GET '/users/1,2');
                is($res->code, 200) or note $res->content;
            };
            {
                my $res = $cb->(GET '/users/foo');
                is($res->code, 400) or note $res->content;
            }
            {
                my $res = $cb->(GET '/users');
                is($res->code, 404) or note $res->content;
            }
            {
                my $res = $cb->(GET '/users/');
                is($res->code, 404) or note $res->content;
            }
            {
                my $res = $cb->(GET '/users/1/foo');
                is($res->code, 404) or note $res->content;
            }
        };
};

done_testing;
