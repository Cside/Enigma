# NAME

Enigma - Amon2::Lite-based framework for API server

# SYNOPSIS

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

# FUNCTIONS

- `get $path, $code;`
- `post $path, $code;`
- `put $path, $code;`
- `patch $path, $code;`
- `del $path, $code;`
- `head $path, $code;`
- `options $path, $code;`
- `$c->render_json($hashref_or_arrayref);`
- `$c->render_json_with_code($status_code, $hashref_or_arrayref);`

# LICENSE

Copyright (C) Hiroki Honda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Hiroki Honda 
