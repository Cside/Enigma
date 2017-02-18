package Enigma;
use common::sense;
use Amon2::Web;
use Amon2::Lite;
use Amon2::Trigger;
use Sub::Install;
use JSON;
use Data::Validator;

our $VERSION = "0.01";

Sub::Install::install_sub({
    into => 'Amon2::Web',
    as   => 'render_json_with_code',
    code => sub {
        my ($self, $code, $data) = @_;
        my $res = $self->render_json($data);
        $res->status($code);
        return $res;
    },
});

Sub::Install::install_sub({
    # TODO Plack::Request に生やしたほうがそれっぽくね？
    into => 'Amon2::Web',
    as   => 'validate',
    code => sub {
        # TODO $rule は reference じゃなくても良いのでは？
        my ($self, $rule) = @_;
        my $validator = Data::Validator->new(%$rule)->with('NoThrow');;

        my $params = eval { decode_json $self->req->content };
        return (undef, $self->render_error_json(400, { errors => ['Malformed JSON'] }))
          if $@;

        $validator->validate(%$params);

        my @errors;
        if ($validator->has_errors) {
            my $errors = $validator->clear_errors;
            push @errors, $_->{message} for @$errors;
        }
        # TODO 生のエラーそのまま返すのはどうなの...。開発時は便利だけど。
        my $error_res = $self->render_error_json(400, { errors => \@errors }) if @errors;

        return $params, $error_res;
    },
});

sub import {
    my ($class) = @_;
    no strict 'refs';
    no warnings 'redefine';

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
        get post
        add_trigger router to_app
    )) {
        no warnings 'redefine';
        Sub::Install::install_sub({
            into => $caller,
            as   => $method,
            code => \&{__PACKAGE__ . "::$method"},
        });
    }
}


1;
__END__

=encoding utf8


=head1 NAME

Enigma - Amon2::Lite-based framework for API server


=head1 SYNOPSIS

    use Enigma;
    
    get '/' => sub {
        my $c = shift;
        $c->render_json({ message => 'OK' });
    };
    
    post '/' => sub {
        my $c = shift;
        $c->validate({
            foo => 'Str',
            bar => { isa => 'Int', optional => 1 },
        });
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

=item C<< $c->render_text($text) >>

=item C<< $c->render_json($hashref_or_arrayref) >>

=item C<< $c->render_json_with_code($status_code, $hashref_or_arrayref) >>

=back


=head1 LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 AUTHOR

Hiroki Honda 

