use strict;

use Test::More;
use Text::M17N;
use IO::File;

eval 'use DBI';
plan skip_all => 'needs DBI for testing' if $@;
eval 'use DBD::SQLite';
plan skip_all => 'needs DBD::SQLite for testing' if $@;
my $dbh = DBI->connect('dbi:SQLite:dbname=test.db', '', '');
plan $dbh ? (tests => 7) : ('skip_all' => 'SQLite connection fail');

$dbh->do(<<'END_SQL');
CREATE TABLE m17n(
       jp TEXT,
       en TEXT
);
END_SQL

my $jp_fh = IO::File->new('./t/lang/jp', 'r');
$jp_fh->binmode(':utf8');
my @jp = map{
   my $data = $_;
   chomp($data);
   $data;
} <$jp_fh>;
$jp_fh->close;

my $en_fh = IO::File->new('./t/lang/en', 'r');
$en_fh->binmode(':utf8');
my @en = map{
   my $data = $_;
   chomp($data);
   $data;
} <$en_fh>;
$en_fh->close;

my $sth = $dbh->prepare('INSERT INTO m17n (jp, en) values (?, ?);');
foreach my $i (0 .. $#jp){
	$sth->execute($jp[$i], $en[$i]);
}
$sth->finish;

my $obj = Text::M17N->new(
    dbh   => $dbh,
    table => 'm17n',
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

eval{ $obj->input_lang(q|en FROM m17n; SELECT mysql.user FROM mysql WHERE 'a' = 'a'; SELECT en|); }; # SQL Injection
like($@, qr{^Language name can use only ascii and number});

$dbh->disconnect;
unlink 'test.db';