package File::Listing::Ftpcopy;

use strict;
use warnings;
use v5.10.1;
use parent qw( Exporter );
use Carp qw( croak );
use Time::Local qw( timelocal );

# ABSTRACT: parse directory listing using ftpparse from ftpcopy
# VERSION

=head1 SYNOPSIS

 # traditional interface
 use File::Listing::Ftpcopy qw(parse_dir);
 $ENV{LANG} = "C";  # dates in non-English locales not supported
 for (parse_dir(`ls -l`)) {
     ($name, $type, $size, $mtime, $mode) = @$_;
     next if $type ne 'f'; # plain file
     #...
 }

 # directory listing can also be read from a file
 open(LISTING, "zcat ls-lR.gz|");
 $dir = parse_dir(\*LISTING, '+0000');

 # ftpparse interface
 use v5.10;
 use Parse::Listing::Ftpcopy qw( ftpparse SIZE_UNKNOWN );
 
 foreach my $line (`ls -l`)
 {
   chomp $line;
   my $h = ftpparse($line);
   next unless defined $h;
   say "name : ", $h->{name}
   say "size : ", $h->{size} if $h->{sizetype} != SIZE_UNKNOWN;
 }

=head1 DESCRIPTION

This module provides functions for parsing the output of directory listings
of the sort generated by an FTP server.  It is intended to provide a mostly
drop in replacement for the C<parse_dir> function from L<File::Listing>
(although see CAVEATS below) that uses the C<ftpparse> function from C<ftpcopy>
(see URL in the SEE ALSO section below) instead of the Perl implementation
provided by L<File::Listing>.  C<ftpparse> is written in C, and so may or may
not be faster, although probably unnoticeable unless you are parsing a recursive
directory listing of a large system, and if you have to do that maybe you should
rethink your approach anyway.

Where this module may come in handy over L<File::Listing> is that it understands
the output from a different subset of systems.  For my purposes, C<ftpparse>
understands VMS listings, on the other hand, L<File::Listing> understands
Apache listings, neither module understands both.  If you know ahead of time
which system you are going to be dealing with you can use either this module
or L<File::Listing>, or if you do not know ahead of time, you can try each 
and use the results from which ever one actually works (or works best).

This module supports the following file listings:

=over 4

=item *

EPLF

=item *

UNIX ls, with or without gid

=item *

Different Windows and DOS FTP servers.

=item *

VMS, but not CMS

=item *

NetPresenz (Mac)

=item *

NetWare

=back

This module also provides a direct interface to the C<ftpparse> function as well.

=head1 FUNCTIONS

=head2 parse_dir( $listing, [ $time_zone, [ $type, [ $error ] ] ] )

The first argument ($listing) is the directory listing to parse.
It can be a scalar, a reference to an array of directory lines or a
glob representing a filehandle to read the directory listing from.

The second argument ($time_zone) is used when parsing the time
stamps in the listing.  If the value is undefined, then the local
time zone is assumed.

The third argument ($type) is ignored, but included here for compatibility
with L<File::Listing>.

The fourth argument ($error) specifies how unparseable lines should
be treated.  Values can be 'ignore', 'warn' or a code reference.
'warn' means that the perl C<warn> function will be called.  If a 
code reference is passed, then this routine will be called and the
return value from it will be incorporated in the listing.  The
default is 'ignore'.

For each file found in the listing it returns an array ref

 foreach my $fileinfo (parse_dir($listing))
 {
   ($name, $type, $size, $mtime, $mode) = @$fileinfo;
   # ...
 }
 
The first element ($name) is the name of the file.

The second element ($size) is the size of the file.

The third element ($mtime) is the modification time of the file.

The forth element ($mode) is supposed to be the permission bits
of the file, but C<ftpparse> ignores the permission information
so this is always undef.

Any field which could not be determined by the algorithm will be
C<undef>.

=cut

sub parse_dir ($;$$$)
{
  my($listing, $time_zone, $type, $error) = @_;
  
  $error = sub { warn shift } if ($error//'') eq 'warn';

  my $next;
  if(ref($listing) eq 'ARRAY')
  {
    my @lines = @$listing;
    $next = sub { shift @lines };
  }
  elsif(ref($listing) eq 'GLOB')
  {
    $next = sub {
      my $line = <$listing>;
      $line;
    };
  }
  elsif(ref $listing)
  {
    croak "Illegal argument to parse_dir()";
  }
  elsif($listing =~ /^\*\w+(::\w+)+$/)
  {
    $next = sub {
      my $line = <$listing>;
      $line;
    };
  }
  else
  {
    my @lines = split /\015?\012/, $listing;
    $next = sub { shift @lines };
  }
  
  my @answer;
  
  my $line = $next->();
  while(defined $line)
  {
    chomp $line;
    my $h = _parse_dir($line);
    if(defined $h)
    {
      my $mtimetype = pop @$h;
      if($mtimetype == MTIME_LOCAL())
      {
        if(defined $time_zone)
        {
          my $secs = localtime($h->[3]);
          local $ENV{TZ} = $time_zone;
          $h->[3] = timelocal($secs);
        }
      }
      elsif($mtimetype == MTIME_REMOTEMINUTE()
      ||    $mtimetype == MTIME_REMOTEDAY()
      ||    $mtimetype == MTIME_REMOTESECOND())
      {
        if(defined $time_zone)
        {
          local $ENV{TZ} = $time_zone;
          $h->[3] = timelocal(gmtime($h->[3]));
        }
        else
        {
          $h->[3] = timelocal(gmtime($h->[3]));
        }
      }
      push @answer, $h;
    }
    elsif(defined $error)
    {
      $error->($line)
    }
    $line = $next->();
  }
  
  return wantarray ? @answer : \@answer;
}

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

0 if the file is definitely not a directory.  1 otherwise.

=item *

flagtryretr

0 if the file is definitely not a regular file or symlink, which can be retrieved.  1 otherwise.

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

our @EXPORT = qw( parse_dir );

our %EXPORT_TAGS = (all => [qw(
  parse_dir
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

=head1 CAVEATS

Because C<ftpparse> does not parse out permission information, the mode field is
always undef.

C<ftpparse> uses a different algorithm, and uses a different interface under the covers,
it recognizes a different subset of system listings, and may interpret them differently
so this module is not, and does not pretend to be 100% compatible with L<File::Listing>.

Internally C<ftpparse> assumes GMT if it can't determine the time zone from the listing,
and doesn't provide an interface for specifying another time zone if you do happen to
know what the remote server's time zone is.  L<File::Listing> assumes the listing is
for the local time zone unless you specify one through the calling interface.  In order
to get the expected behavior for C<parse_dir>, this module jumps through some extra
hoops to support the L<File::Listing> interface.  To avoid these hoops use the C<ftpparse>
interface instead.

The C<ftpparse> function from C<ftpcopy> is based on C<ftpparse> by Daniel J. Bernsteins.
Bernsteins' version is incompatible with GPL, and possibly other open source licenses.
The C<ftpparse> function from C<ftpcopy> was written by Uwe Ohse and is mostly public
domain, but there was one dependent C source file which was licensed under GPL 2, so I
am licensing this whole distribution under GPL 2.

=cut

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
