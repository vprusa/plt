#!/usr/bin/perl -w
########################################################################
# Perl Logging Tool
# Author: Vojtech Prusa (prusa.vojtech@gmail.com), 2021
########################################################################

=pod
This file contains configuration for PTL and main.
Values here can be overwritten by command line arguments.
Possible TODOs:
- Split into several files,
- Devel vs Sharp version - not versioned
- Default file - versioned
=cut

package PltConf;

# use strict;
# use warnings;
use 5.008003; # may be newer

use Cwd 'abs_path';
use File::Basename;

use Data::Dumper qw(Dumper);
use Getopt::Long qw(GetOptions);
use experimental 'smartmatch';

no warnings "experimental::refaliasing";
use feature "refaliasing";
use Data::Dumper qw(Dumper);

use POSIX qw/floor/;

my $VERSION = '0.8.0';

=pod
History:
Run modes are based on previous project that I was refactoring,
Devel
- mode used devel DB but yet it could also be split into
Debug
- mode that used just selected part of Devel DB and so development and debuging was easier and faster
=cut
# enable (1) if debug
#our $debug = 0;
our $debug = 1;
# enable (1) if devel
#our $devel = 0;
our $devel = 1;

#our $cur_dir = dirname(abs_path($0));
my $cur_dir = dirname(__FILE__);
chomp $cur_dir;
#require $cur_dir . "/plt.pl";



our %CF_secret = (
  DEVEL => 1,
  DEBUG => 1,

  RUN_AS        => 'LOCAL',
  # TODO rewrite as needed, adding new remotes needs change in plt.pl or generalization of this concept
  SSH_TEST         => 'ssh test',
  SSH_SHARP        => 'ssh sharp',
  # TODO fix: variables used in plt.pl has to be loaded here
  PRINT_WS => '  ',
  # PRINT_WS => '\t',
  PREFIX_BLOCK_WS => '  ',
  PRINT_ERROR_CODE => 1,
  PRINT_RESULT => 1,
  PRINT_OPTS => 1,
);
# print "plt_config.pl::CF_secret: \n" . Dumper(\%CF_secret);

=pod
In theory this could be split to multiple files per log message type
TODO ...
=cut
our $debug_only_log_file_path = "$cur_dir/debugOnly.log";

if ($devel) {
  # TODO print=> Log(...)
  if ($debug == 1) {
    # sample configurations for debug purposes, possibly with configurable switch...
  }
} else {
}

sub does_contain_var {
  my (%CF) = @_;
  foreach $i (keys %CF) {
    return 1 if ($CF{$i} =~ m/\{\{/);
  }
  return 0;
}

my $rec_limit = 5;
sub fill_CF {
  my (%CF, %other);
  if (scalar(@_) > 1) {
    my ($CF_ref, $other_ref) = @_;
    %CF = %{$CF_ref}; # dereferencing and copying each array
    %other = %{$other_ref};
  } else {
    %CF = %{$CF_ref}; # dereferencing and copying each array
  }

  my $while_limit = $rec_limit * scalar(%CF) / 2;
  my $i = 0;
  while (does_contain_var(%CF) && $while_limit > $i) {
    $i += 1;
    foreach $i (keys %CF) {
      foreach $j (keys %CF) {
        my $replace = '\{\{' . $j . '\}\}';
        $CF{$i} =~ s/$replace/$CF{$j}/;
        for $k (keys %other) {
          if ($k =~ m/^param_.*|^p_.*/) {
            $replace = '\{\{' . $k . '\}\}';
            $CF{$i} =~ s/$replace/$other{$k}/;
          }
        }
      }
    }
  }
  # print Dumper(\%CF);
  return %CF;
}
# print "Not empty: \n" . Dumper(\%CF_secret);
# %CF_secret = fill_CF(%CF_secret);


1;
