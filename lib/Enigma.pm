package Enigma;
use common::sense;
use Amon2::Web;
use Amon2::Lite;
use Amon2::Trigger;
use Amon2::Plugin::Web::JSON;
use Amon2::Plugin::Web::Text;
use Sub::Install;
use Data::Clone qw(clone);
use JSON;
use Data::Validator;
use Plack::Builder;
use Plack::Util;
use Plack::Middleware::DebugRequestParams;
use HTTP::Status qw(:constants :is status_message);

our $VERSION = "0.01";

no warnings 'redefine';

Sub::Install::install_sub({
    into => 'Amon2::Web',
    as   => 'render_json_with_code',
    code => sub {
        my ($c, $code, $data) = @_;
        unless ($data) {
            if (is_success($code)) {
                $data = {
                    message => status_message($code),
                };
            } else {
                $data = {
                    errors => [
                        { message => status_message($code) }
                    ]
                };
            }
        }
        my $res = $c->render_json($data);
        $res->status($code);
        return $res;
    },
});

Sub::Install::install_sub({
    into => 'Amon2::Web',
    as   => '_error_res',
    code => sub {
        my ($c, $code, $messages) = @_;
        return $c->render_json_with_code($code, [
            map { +{ message => $_ } }
            @$messages
        ]);
    },
});

Sub::Install::install_sub({
    into => 'Amon2::Web',
    as   => 'error_res',
    code => sub {
        my ($c, $res) = @_;
        $c->{error_res} = $res if $res;
        return $c->{error_res};
    },
});

my %VALIDATORS;
Sub::Install::install_sub({
    into => 'Amon2::Web',
    as   => 'validate',
    code => sub {
        my ($c, %rule) = @_;
        my ($package, undef, $line) = caller(0);
        # XXX 果たしてこれで呼び出し元が unique に特定できるのかは疑問が残る
        my $key = sprintf '%s:%d', $package, $line;
        my $validator = $VALIDATORS{$key} ||= Data::Validator->new(%rule)->with('NoThrow');;
        my $p = clone($c->{p});

        my $params = do {
            my $json_params = ( ($c->req->header('content-type') || "") =~ m|application/json|)
                              ? eval { decode_json( $c->req->content); } || {}
                              : {};
            my $params = $c->req->parameters;
            my $path_parameter = do {
                delete $p->{method};
                delete $p->{code};
                $ENV{_DEBUG_REQUEST_PARAMS} = encode_json($p) if %$p;
                $p;
            };

            +{
                %$json_params,
                %$params,
                %$path_parameter,
            };
        };
        if ($@) {
            $c->error_res(
                $c->_error_res(400, ['Malformed JSON']),
            );
            return;
        }

        $validator->validate(%$params);

        my @errors;
        if ($validator->has_errors) {
            my $errors = $validator->clear_errors;
            push @errors, $_->{message} for @$errors;
        }
        if (@errors) {
            # XXX 生のエラーそのまま返すのはどうなの...。開発時は便利だけど。
            $c->error_res(
                $c->_error_res(400, \@errors),
            );
            return;
        }

        return $params;
    },
});

sub import {
    my ($class) = @_;
    no strict 'refs';

    my $caller = caller(0);

    my $base_class = 'Amon2::Lite::_child_0';
    unshift @{"$base_class\::ISA"}, qw(Amon2 Amon2::Web);
    unshift @{"$caller\::ISA"}, $base_class;

    $caller->load_plugins(qw/Web::JSON/);
    $caller->load_plugins(qw/Web::Text/);

    for my $pair (
        ['put',     'PUT'],
        ['del',     'DELETE'],
        ['patch',   'PATCH'],
        ['head',    'HEAD'],
        ['options', 'OPTIONS'],
    ) {
        Sub::Install::install_sub({
            into => $caller,
            as   => $pair->[0],
            code => sub {
                router->connect(
                    $_[0],
                    { code => $_[1], method => [$pair->[1]] },
                    { method => $pair->[1] },
                );
            },
        });
    }

    for my $method (qw(
        get post any
        add_trigger router
    )) {
        Sub::Install::install_sub({
            into => $caller,
            as   => $method,
            code => \&{__PACKAGE__ . "::$method"},
        });
    }

    Sub::Install::install_sub({
        into => $base_class,
        as   => 'to_app',
        code => sub {
        },
    });
    *{"${base_class}\::dispatch"} = sub {
        my ($c) = @_;
        if (my $p = router->match($c->req->env)) {
            $c->{p} = $p;
            return $p->{code}->($c);
        } else {
            if (router->method_not_allowed) {
                return $c->render_json_with_code(405, { message => 'Method Not Allowed'});
            }
            return $c->render_json_with_code(404, { message => 'Not Found'});
        }
    };


    Sub::Install::install_sub({
        into => $caller,
        as   => 'to_app',
        code => sub {
            my ($class, %opts) = @_;

            my $app = &{__PACKAGE__ . "::to_app"}($class, %opts);

            return builder {
                enable sub {
                    my $app = shift;
                    sub {
                        my $res = $app->($_[0]);

                        my $header = Plack::Util::headers($res->[1]);

                        # TODO ガバガバだけどあとで直す
                        $header->set('Access-Control-Allow-Origin' => '*');
                        $header->set('Access-Control-Allow-Methods' => join(', ', qw( POST GET PUT DELETE HEAD OPTIONS )));
                        $header->set('Access-Control-Allow-Headers' => join(', ', qw( Content-Type X-Requested-With )));

                        $header->set('Pragma'        => 'no-cache');
                        $header->set('Cache-Control' => 'no-cache');

                        return $res;
                    };
                };
                enable "DebugRequestParams"
                    if ($ENV{PLACK_ENV} || '') eq '' || $ENV{PLACK_ENV} eq 'development';
                return $app;
            };
        },
    });
}

1;
__END__

=encoding utf8


=head1 NAME

Enigma - Amon2::Lite-based framework for API server


=head1 SYNOPSIS

    use Enigma;
    
    get '/' => sub {
        my ($c) = @_;
        $c->render_json({ message => 'OK' });
    };
    
    put '/' => sub {
        my ($c) = @_;
        $c->validate(
            foo => 'Str',
            bar => { isa => 'Int', optional => 1 },
        ) or return $c->error_res;
        ...
        $c->render_json_with_code(201, { message => 'created' });
    };
    
    __PACKAGE__->to_app;


=head1 FUNCTIONS

=over

=item C<< get $path, $code; >>

=item C<< post $path, $code; >>

=item C<< put $path, $code; >>

=item C<< patch $path, $code; >>

=item C<< del $path, $code; >>

=item C<< head $path, $code; >>

=item C<< options $path, $code; >>

=item C<< $c->render_json($hashref_or_arrayref); >>

=item C<< $c->render_json_with_code($status_code, $hashref_or_arrayref); >>

=back


=head1 LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

Hiroki Honda 

