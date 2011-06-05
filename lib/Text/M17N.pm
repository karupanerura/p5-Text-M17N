package Text::M17N;
use strict;
use warnings;

our $VERSION = '0.01';

use Carp;
use File::Spec;

sub new{
    my $class = shift;
    
    my $self = bless(((scalar(@_) == 1) ? @_ : +{@_}) => $class);
    
    if(defined($self->{dbh}) and defined($self->{dbh}) and defined($self->{table})){
	$self->{_dbi_mode} = 1;
    }elsif(not(defined($self->{lang_dir}) and -d $self->{lang_dir})){
	die(q|"lang_dir" option require directory.|) ;
    }

    $self->{lang}          = +{};
    $self->{_table}        = +{};
    $self->{input_layer} ||= ':utf8';
    $self->input_lang($self->{input_lang})   if defined $self->{input_lang};
    $self->output_lang($self->{output_lang}) if defined $self->{output_lang};

    return $self;
}

sub load_lang{
    my($self, $lang) = @_;
    
    return $self->{lang}{$lang} ||= do{
	$self->{_dbi_mode} ?
	    $self->_load_lang_db($lang):
	    $self->_load_lang($lang);
    } or die(qq|${lang} load faild.|);
}

sub _load_lang{
    my($self, $lang) = @_;

    my $lang_file = File::Spec->catfile($self->{lang_dir}, $lang);

    die(qq|Don't found "$lang_file".|) unless(-f $lang_file);

    open(my $file, '<', $lang_file) or return;
    binmode($file, $self->{input_layer});
    my @data = map{
	my $data = $_;
	chomp($data);
	$data;
    } <$file>;
    close($file) or return;

    return \@data;
}

my $__ok__ = qr{^[a-zA-Z0-9]+$}o; # SQL injection filter
sub _load_lang_db{
    my($self, $lang) = @_;
    
    croak(q|Table name can use only ascii and number.|)    unless( $self->{table} =~ $__ok__ );
    croak(q|Language name can use only ascii and number.|) unless( $lang          =~ $__ok__ );
        
    my $_tmp = $self->{dbh}->selectall_arrayref("SELECT $lang FROM " . $self->{table}) or return;
    my @data = map{ $_->[0] } @{$_tmp};

    return \@data;
}

sub input_lang{
    my($self, $lang) = @_;

    $self->{input_lang} = $lang;
    $self->{_table}{$lang} ||= +{};

    return $self->load_lang($lang);
}
 
sub output_lang{
    my($self, $lang) = @_;

    $self->{output_lang} = $lang;

    return $self->load_lang($lang);
}

sub convert{
    my($self, $text) = @_;
    
    my $in  = $self->{input_lang};
    my $out = $self->{output_lang};

    my $hash_table =
	$self->{_table}{$in}{$out} ||= $self->make_table($in, $out);

    return $hash_table->{$text} or die('convert faild.');
}

sub make_table{
    my($self, $in, $out) = @_;

    my $table = +{};
    my @input = @{$self->{lang}{$in}};
    
    foreach my $i (0 .. $#input){
	$table->{$input[$i]} = $self->{lang}{$out}->[$i];
    }
    
    return $table;
}

sub converter{
    my $self = shift;

    return sub{ $self->convert(shift); };
}

*c = *convert;

1;
__END__

=head1 NAME

Text::M17N - Simple text multi-lingualization processor

=head1 SYNOPSIS

  use Text::M17N;

  my $encoder = Text::M17N->new(
    lang_dir   => './lang',
    input_lang => 'ja'
  );

  $encoder->output_lang('en');
  print $encoder->convert('こんにちは！'); # print"Hello!"
  print $encoder->c('こんにちは！'); # print"Hello!" (alias)
  my $c = $encoder->converter;
  $c->('こんにちは！'); # print"Hello!"

or

  use DBI;
  use Text::M17N;

  my $encoder = Text::M17N->new(
    dbh   => DBI->connect(...),
    table => 'm17n',
    input_lang => 'ja'
  );

  # CREATE TABLE m17n(
  #   jp TEXT,
  #   en TEXT
  # );

  $encoder->output_lang('en');
  print $encoder->convert('こんにちは！'); # print"Hello!"
  print $encoder->c('こんにちは！'); # print"Hello!" (alias)
  my $c = $encoder->converter;
  $c->('こんにちは！'); # print"Hello!"

=head1 DESCRIPTION

Text::M17N is text multi-lingualization support.
This module have simple interface, and easy to use.

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
