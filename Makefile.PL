use ExtUtils::MakeMaker;
use v5.10.1;

##{ $share_dir_code{preamble} || '' ##}

my %args = (
  NAME => 'File::Listing::Ftpcopy',
##{ $plugin->get_default(qw( ABSTRACT AUTHOR LICENSE VERSION )) ##}
##{ $plugin->get_prereqs ##}
  OBJECT => do {
    opendir $fd, '.';
    my %obj = map {; $_ => 1 } grep { s/\.(c|xs)$/.o/ } grep !/^\./, readdir $fd;
    closedir $fd;
    join(' ', keys %obj)
  }
);

system $^X, 'typesize.pl';

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}
 
delete $args{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };
 
delete $args{LICENSE}
  unless eval { ExtUtils::MakeMaker->VERSION(6.31) };
 
WriteMakefile(%args);
 
##{ $share_dir_code{postamble} || '' ##}
