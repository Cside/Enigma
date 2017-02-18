requires 'Amon2::Lite';
requires 'Amon2::Trigger';
requires 'Amon2::Web';
requires 'Amon2::Plugin::Web::Text';
requires 'Amon2::Plugin::Web::JSON';
requires 'Data::Validator';
requires 'JSON';
requires 'Sub::Install';
requires 'common::sense';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'Path::Tiny';
    requires 'Plack::Test';
    requires 'Plack::Util';
    requires 'Test::Exception';
    requires 'Test::More', '0.98';
};
