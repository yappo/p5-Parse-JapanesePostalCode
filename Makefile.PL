use inc::Module::Install;
name 'Parse-JapanesePostalCode';
all_from 'lib/Parse/JapanesePostalCode.pm';
readme_from 'lib/Parse/JapanesePostalCode.pm';
readme_markdown_from 'lib/Parse/JapanesePostalCode.pm';
githubmeta;

requires 'parent';
requires 'Lingua::JA::Regular::Unicode';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
WriteAll;
