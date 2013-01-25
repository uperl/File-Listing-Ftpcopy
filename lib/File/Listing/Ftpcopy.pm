package File::Listing::Ftpcopy;

use strict;
use warnings;
use v5.10.1;
use base qw( Exporter );
use Carp qw( croak );

# ABSTRACT: parse directory listing using ftpparse from ftpcopy
# VERSION

=head1 SYNOPSIS

 # ftpparse interface
 use v5.10;
 use Parse::Listing::Ftpcopy qw( :all );
 
 foreach my $line (`ls -l`)
 {
   chomp $line;
   my $h = ftpparse($line);
   next unless defined $h;
   say "name : $h{name}";
   say "size : $h{size}" if $h{sizetype} != SIZE_UNKNOWN;
 }

=head1 METHODS

=head2 ftpparse( $line )

Parse a single line from an FTP listing.  Returns a hash ref of
information about the file found in that line, or undef if no
file information was found about the file.

Here is the information found in the hash ref:

=over 4

=item *

name

The name of the file

=item *

size

The size of the file

=item *

sizetype

What format the size refers to, one of

=over 4

=item *

SIZE_UNKNOWN

The size could not be determined (size is set to 0)

=item *

SIZE_BINARY

The size assumes a binary transfer (TYPE I)

=item *

SIZE_ASCII

The size assumes an ASCII transfer (TYPE A)

This is currently unused, but could theoretically be used in the future.

=back

=item *

flagtrycwd

0 if the file is defintely not a directory.  1 otherwise.

=item *

flagtryretr

0 if the file is defintely not a regular file or symlink, which can be retrieved.  1 otherwise.

=item *

symlink

If the file is a symlink, then this contains the target name (or at least part of the target name)
of the symlink.

=item *

format

The detected format of the listing, one of:

=over 4

=item *

FORMAT_UNKNOWN

=item *

FORMAT_EPLF

=item *

FORMAT_MLSX

=item *

FORMAT_LS

=back

=item *

mtime

The modification time as the number of non-leap seconds since
the epoch.

=item *

mtimetype

Information about the mtime field, one of:

=over 4

=item *

MTIME_UNKNOWN 

modification time is undetermined

=item *

MTIME_LOCAL

time is correct for the current time zone

=item *

MTIME_REMOTEMINUTE

Time zone and seconds are unknown

=item *

MTIME_REMOTEDAY

Time zone and time of day are unknown

=item *

MTIME_REMOTESECOND

time zone is unknown

=back

=back

=cut

our %EXPORT_TAGS = (all => [qw(
  ftpparse
  FORMAT_EPLF
  FORMAT_LS
  FORMAT_MLSX
  FORMAT_UNKNOWN
  ID_FULL
  ID_UNKNOWN
  MTIME_LOCAL
  MTIME_REMOTEDAY
  MTIME_REMOTEMINUTE
  MTIME_REMOTESECOND
  MTIME_UNKNOWN
  SIZE_ASCII
  SIZE_BINARY
  SIZE_UNKNOWN
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

require XSLoader;
XSLoader::load('File::Listing::Ftpcopy', $VERSION);

sub AUTOLOAD
{
  my $name;
  our $AUTOLOAD;
  ($name = $AUTOLOAD) =~ s/.*:://;
  croak "$AUTOLOAD not defined" if $name eq 'constant';
  my $val = constant($name);
  croak "$AUTOLOAD not defined" if $val == -1;
  do {
    no strict 'refs';
    *$AUTOLOAD = sub { $val };
  };
  goto &$AUTOLOAD;
}

1;

# http://perldoc.perl.org/perlxstut.html
# http://perldoc.perl.org/perlguts.html
# http://old.nabble.com/*URGENT*-ftpparse-licensing-issue-to61623.html
# http://fossies.org/dox/ftpcopy-0.6.7/index.html
# http://woodsheep.jp/wget-ftpparse/wget-1.5.3-ftpparse-19970712-0.52.patch

=head1 SEE ALSO

=over 4

=item *

L<File::Listing>

=item *

L<http://ohse.de/uwe/ftpcopy/install.html>

=item *

L<http://cr.yp.to/ftpparse.html>

=back

=cut
