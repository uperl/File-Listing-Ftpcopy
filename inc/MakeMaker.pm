package inc::MakeMaker;

use Moose;
use namespace::autoclean;
use v5.10;

with 'Dist::Zilla::Role::InstallTool';

sub setup_installer
{
  my($self) = @_;

  my($makefile) = grep { $_->name eq 'Makefile.PL' } @{ $self->zilla->files };
  
  my $content = $makefile->content;
  
  state $checks;
  unless($checks)
  {
    $checks = do { local $/; <DATA> };
  }
  
  if($content =~ s{(WriteMakefile\()}{$checks$1}m)
  {
    $makefile->content($content);
    $self->zilla->log("Modified Makefile.PL with extra checks");
  }
  else
  {
    $self->zilla->log_fatal("unable to update Makefile.PL");
  }
}

1;

__DATA__

$WriteMakefileArgs{OBJECT} = do {
  my $fd;
  opendir $fd, '.';
  my %obj = map {; $_ => 1 } grep { s/\.(c|xs)$/.o/ } grep !/^\./, readdir $fd;
  closedir $fd;
  join(' ', keys %obj)
};

system $^X, 'typesize.pl';


