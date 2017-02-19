requires 'Amon2::Lite';
requires 'Amon2::Plugin::Web::JSON';
requires 'Amon2::Plugin::Web::Text';
requires 'Amon2::Trigger';
requires 'Amon2::Web';
requires 'Data::Clone';
requires 'Data::Validator';
requires 'JSON';
requires 'Minilla::Project';
requires 'Plack::Builder';
requires 'Plack::Middleware::DebugRequestParams';
requires 'Plack::Util';
requires 'Sub::Install';
requires 'common::sense';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'HTTP::Request::Common';
    requires 'Plack::Test';
    requires 'Test::Exception';
    requires 'Test::More', '0.98';
};

requires 'App::scan_prereqs_cpanfile';
