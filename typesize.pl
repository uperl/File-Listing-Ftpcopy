use strict;
use Config;
use warnings;
use v5.10.1;
use autodie;
use File::Spec;
use File::Temp qw( tempdir );

my $dir = tempdir( CLEANUP => 1 );

my @types = ("short", "int", "long ", "unsigned short", "unsigned int", 
"unsigned long", "long long", "unsigned long long");

my $counter = 0;

open my $header, '>', 'auto-typesize.h';

foreach my $type (@types)
{
  my $src = File::Spec->catfile($dir, "$counter.c");
  my $obj = File::Spec->catfile($dir, "$counter$Config{obj_ext}");
  my $bin = File::Spec->catfile($dir, "$counter.exe");
    
  $counter++;
  
  open my $out, '>', $src;
  say $out "int main() {";
  say $out "  $type t;";
  say $out "  return sizeof(t);";
  say $out "}";
  close $out;
  
  run("$Config{cc} $Config{ccflags} -c -o $obj $src");
  next if $?;
  
  run("$Config{ld} $Config{ldflags} -o $bin $obj");
  next if $?;
  
  run($bin, 'bogus'); # avoid calling the shell
                         # by passing bogus argument
  next if $? == -1 || $? & 127;
  my $size = $? >> 8;
  
  my $def_type = uc 'sizeof ' . $type;
  $def_type =~ s/ /_/g;
  say $header "#define $def_type $size /* systype-info */";
  say sprintf("%02d %s", $size, $type);
}

close $header;

sub run
{
  #say "% @_";
  system @_;
}
