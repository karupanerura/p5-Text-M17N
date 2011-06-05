use inc::Module::Install;
name 'Text-M17N';
all_from 'lib/Text/M17N.pm';
readme_from 'lib/Text/M17N.pm';
readme_pod_from 'lib/Text/M17N.pm';
githubmeta;

# requires '';

tests 't/*.t';
author_tests 'xt';

requires 'File::Spec';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
