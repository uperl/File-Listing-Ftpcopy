use strict;
use warnings;
use Test::More tests => 1;
use File::Listing::Ftpcopy;

is File::Listing::Ftpcopy::ftpparse(''), undef, 'not found';
