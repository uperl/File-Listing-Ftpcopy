package File::Listing::Ftpcopy;

use strict;
use warnings;
use v5.10.1;

# ABSTRACT: parse directory listing using ftpparse from ftpcopy
# VERSION

require XSLoader;
XSLoader::load('File::Listing::Ftpcopy', $VERSION);

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
