use strict;
use warnings;
use Test::More tests => 1;
use File::Listing::Ftpcopy ();

is File::Listing::Ftpcopy::return42(), 42, 'return42 returns 42';
