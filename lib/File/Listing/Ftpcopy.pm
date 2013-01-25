package File::Listing::Ftpcopy;

use strict;
use warnings;
use v5.10.1;
use base qw( Exporter );
use Carp qw( croak );

# ABSTRACT: parse directory listing using ftpparse from ftpcopy
# VERSION

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
