# File::Listing::Ftpcopy [![Build Status](https://secure.travis-ci.org/plicease/File-Listing-Ftpcopy.png)](http://travis-ci.org/plicease/File-Listing-Ftpcopy)

parse directory listing using ftpparse from ftpcopy

# SYNOPSIS

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
    use 5.010;
    use Parse::Listing::Ftpcopy qw( ftpparse SIZE_UNKNOWN );
    
    foreach my $line (`ls -l`)
    {
      chomp $line;
      my $h = ftpparse($line);
      next unless defined $h;
      say "name : ", $h->{name}
      say "size : ", $h->{size} if $h->{sizetype} != SIZE_UNKNOWN;
    }

# DESCRIPTION

This module provides functions for parsing the output of directory listings
of the sort generated by an FTP server.  It is intended to provide a mostly
drop in replacement for the `parse_dir` function from [File::Listing](https://metacpan.org/pod/File::Listing)
(although see CAVEATS below) that uses the `ftpparse` function from `ftpcopy`
(see URL in the SEE ALSO section below) instead of the Perl implementation
provided by [File::Listing](https://metacpan.org/pod/File::Listing).  `ftpparse` is written in C, and so may or may
not be faster, although probably unnoticeable unless you are parsing a recursive
directory listing of a large system, and if you have to do that maybe you should
rethink your approach anyway.

Where this module may come in handy over [File::Listing](https://metacpan.org/pod/File::Listing) is that it understands
the output from a different subset of systems.  For my purposes, `ftpparse`
understands VMS listings, on the other hand, [File::Listing](https://metacpan.org/pod/File::Listing) understands
Apache listings, neither module understands both.  If you know ahead of time
which system you are going to be dealing with you can use either this module
or [File::Listing](https://metacpan.org/pod/File::Listing), or if you do not know ahead of time, you can try each 
and use the results from which ever one actually works (or works best).

This module supports the following file listings:

- EPLF
- UNIX ls, with or without gid
- Different Windows and DOS FTP servers.
- VMS, but not CMS
- NetPresenz (Mac)
- NetWare

This module also provides a direct interface to the `ftpparse` function as well.

# FUNCTIONS

## parse\_dir

    my $dir = parse_dir( $listing );
    my $dir = parse_dir( $listing, $time_zone );
    my $dir = parse_dir( $listing, $time_zone, $type );
    my $dir = parse_dir( $listing, $time_zone, $type, $error);

The first argument ($listing) is the directory listing to parse.
It can be a scalar, a reference to an array of directory lines or a
glob representing a filehandle to read the directory listing from.

The second argument ($time\_zone) is used when parsing the time
stamps in the listing.  If the value is undefined, then the local
time zone is assumed.

The third argument ($type) is ignored, but included here for compatibility
with [File::Listing](https://metacpan.org/pod/File::Listing).

The fourth argument ($error) specifies how unparseable lines should
be treated.  Values can be 'ignore', 'warn' or a code reference.
'warn' means that the perl `warn` function will be called.  If a 
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
of the file, but `ftpparse` ignores the permission information
so this is always undef.

Any field which could not be determined by the algorithm will be
`undef`.

## ftpparse

    my $hash = ftpparse( $line );

Parse a single line from an FTP listing.  Returns a hash ref of
information about the file found in that line, or undef if no
file information was found about the file.

Here is the information found in the hash ref:

- name

    The name of the file

- size

    The size of the file

- sizetype

    What format the size refers to, one of

    - SIZE\_UNKNOWN

        The size could not be determined (size is set to 0)

    - SIZE\_BINARY

        The size assumes a binary transfer (TYPE I)

    - SIZE\_ASCII

        The size assumes an ASCII transfer (TYPE A)

        This is currently unused, but could theoretically be used in the future.

- flagtrycwd

    0 if the file is definitely not a directory.  1 otherwise.

- flagtryretr

    0 if the file is definitely not a regular file or symlink, which can be retrieved.  1 otherwise.

- symlink

    If the file is a symlink, then this contains the target name (or at least part of the target name)
    of the symlink.

- format

    The detected format of the listing, one of:

    - FORMAT\_UNKNOWN
    - FORMAT\_EPLF
    - FORMAT\_MLSX
    - FORMAT\_LS

- mtime

    The modification time as the number of non-leap seconds since
    the epoch.

- mtimetype

    Information about the mtime field, one of:

    - MTIME\_UNKNOWN 

        modification time is undetermined

    - MTIME\_LOCAL

        time is correct for the current time zone

    - MTIME\_REMOTEMINUTE

        Time zone and seconds are unknown

    - MTIME\_REMOTEDAY

        Time zone and time of day are unknown

    - MTIME\_REMOTESECOND

        time zone is unknown

# CAVEATS

Because `ftpparse` is written in C and the bindings to it are in XS, so a C compiler
is required.

Because `ftpparse` does not parse out permission information, the mode field is
always undef.

`ftpparse` uses a different algorithm, and uses a different interface under the covers,
it recognizes a different subset of system listings, and may interpret them differently
so this module is not, and does not pretend to be 100% compatible with [File::Listing](https://metacpan.org/pod/File::Listing).

Internally `ftpparse` assumes GMT if it can't determine the time zone from the listing,
and doesn't provide an interface for specifying another time zone if you do happen to
know what the remote server's time zone is.  [File::Listing](https://metacpan.org/pod/File::Listing) assumes the listing is
for the local time zone unless you specify one through the calling interface.  In order
to get the expected behavior for `parse_dir`, this module jumps through some extra
hoops to support the [File::Listing](https://metacpan.org/pod/File::Listing) interface.  To avoid these hoops use the `ftpparse`
interface instead.

The `ftpparse` function from `ftpcopy` is based on `ftpparse` by Daniel J. Bernsteins.
Bernsteins' version is incompatible with GPL, and possibly other open source licenses.
The `ftpparse` function from `ftpcopy` was written by Uwe Ohse and is mostly public
domain, but there was one dependent C source file which was licensed under GPL 2, so I
am licensing this whole distribution under GPL 2.

# SEE ALSO

- [File::Listing](https://metacpan.org/pod/File::Listing)
- [http://ohse.de/uwe/ftpcopy/install.html](http://ohse.de/uwe/ftpcopy/install.html)
- [http://cr.yp.to/ftpparse.html](http://cr.yp.to/ftpparse.html)

# AUTHOR

C code: Uwe Ohse

XS and Perl code: Graham Ollis &lt;plicease@cpan.org>

# COPYRIGHT AND LICENSE

Copyright 2002 by Uwe Ohse

Copyright 2013 by Graham Ollis

This is free software, licensed under the GNU General Public License, 
Version 2, June 1991

Some source files marked as public domain are in the public domain.
