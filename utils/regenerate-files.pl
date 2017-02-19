#!/usr/bin/env perl
use common::sense;
use Minilla::Project;

my $minil = Minilla::Project->new;

$minil->regenerate_meta_json;
$minil->regenerate_readme_md;
