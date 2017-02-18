use common::sense;
use Test::More;
use Test::Exception;
use Enigma;

no strict 'refs';

for my $method (qw(get post put head del options)) {
    can_ok __PACKAGE__, $method;
    lives_ok {
        my $code = \&{__PACKAGE__ . "::$method"};
        $method->('/foo', sub {});
    } "$method can connect";
}

can_ok __PACKAGE__, 'router';
can_ok __PACKAGE__, 'to_app';
isa_ok __PACKAGE__->to_app, 'CODE';

done_testing;
