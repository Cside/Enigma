use common::sense;
use Test::More;
use Test::Exception;
use Plack::Test;
use HTTP::Request::Common;
use Enigma;

for my $pair (
    [ get     => 'GET' ],
    [ post    => 'POST' ],
    [ head    => 'HEAD' ],
    [ del     => 'DELETE' ],
    [ put     => 'PUT' ],
    [ options => 'OPTIONS' ],
    [ patch   => 'PATCH' ],
) {
    my ($func, $method) = @$pair;
    no strict 'refs';
    my $code = \&{__PACKAGE__ . "::$func"};
    $code->('/', sub {
        my $c = shift;
        return $c->render_text('OK');
    });
}
my $app = __PACKAGE__->to_app;

for my $method (qw( GET POST HEAD DELETE PUT OPTIONS PATCH )) {
    subtest 'basic' => sub {
        test_psgi
            app => $app,
            client => sub {
                my $cb  = shift;
                my $req = HTTP::Request->new($method => '/');
                my $res = $cb->($req);
                is $res->code, 200;
                is $res->content, 'OK';
            };
    };
}

done_testing;
