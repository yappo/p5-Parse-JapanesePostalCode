use inc::Module::Install;
name 'Parse-JapaneseZipCode';
all_from 'lib/Parse/JapaneseZipCode.pm';
readme_from 'lib/Parse/JapaneseZipCode.pm';
readme_markdown_from 'lib/Parse/JapaneseZipCode.pm';
githubmeta;

requires 'parent';
requires 'Lingua::JA::Regular::Unicode';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
WriteAll;
