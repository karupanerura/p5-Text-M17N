use strict;
use utf8;
use Test::More tests => 6;
use Text::M17N;

my $obj = Text::M17N->new(
    lang_dir => "./t/lang",
    input_lang => 'jp'
);

$obj->output_lang('en');

is($obj->convert('おはよう'), 'Good morning');
is($obj->c('こんにちは'), 'Hello');

my $c = $obj->converter;
is($c->('こんばんは'), 'Good evening');

$obj->input_lang('en');
$obj->output_lang('jp');

is($obj->convert('Good morning'), 'おはよう');
is($obj->c('Hello'), 'こんにちは');

$c = $obj->converter;
is($c->('Good evening'), 'こんばんは');
