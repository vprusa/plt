#!/usr/bin/perl
########################################################################
# Perl Logging Tool
# Author: Vojtech Prusa (prusa.vojtech@gmail.com), 2021
########################################################################

=pod
TODO:
- split plt_config.pl to plt_config_pub.pl and plt_config_sec.pl and make plt_config_pub.pl load plt_config_sec.pl
- fix packages and includes (require, use)
- cp main.pl examples.pl ; and remove examples and unnecessary code from main.pl
- move some subroutines so main.pl would be easily extendable and as much configuration as possible move to *config*.pl
- remove unnecessary 'use *';
- add examples for DEB, WARN, ERR
=cut

# https://github.com/Camelcade/Perl5-IDEA/wiki/Perl-Debugger
# use strict;
# use warnings;

use warnings FATAL => 'all';
use POSIX qw/floor/;
use File::Basename;
use Cwd 'abs_path';
use Getopt::Long qw(GetOptions);
use Data::Dumper qw(Dumper);

########################################################################
# load variables shared with config
########################################################################

my $cur_dir = dirname(abs_path($0));
my $conf_path = $cur_dir . '/plt_config.pl';
# require $conf_path;
require $cur_dir . "/plt.pl";

our $debug;
our $devel;

########################################################################
# Load configuration and command line arguments
########################################################################

# Set defaults for all the options, then read them in from command line
our %arg = (
  verbose               => 0,
  quiet                 => 0,
  dry                   => 1,
  debug                 => 0,
  help                  => 0,
  mode                  => 0,
  print_args            => 0,
  print_status          => 0,
  print_config          => 0,
  prepare               => 1,
  examples              => 0,
  examples_all          => 0,
  example_args          => 0,
  example_cmd_exec      => 0,
  example_should_ex1    => 0,
  example_should_ex2    => 1,
  example_block_spacing => 0,
  p_days_ago            => 5,
);

our $result = GetOptions(
  \%arg,
  'verbose:i',
  'dry:i',
  'quiet:i',
  'debug:i',
  'help|h',
  'print_args',
  'print_status',
  'print_config',
  'mode=s',
  'prepare:i',
  'examples|exs',
  'examples_all|exs_all',
  'example_args|ex0',
  'example_cmd_exec|ex01',
  'example_should_ex1|ex1',
  'example_should_ex2:i',
  'example_block_spacing|ex3',
  'p_days_ago:i',
) or help();

SPlt::set_dry($arg{'dry'});

=pod
Loading configuration
\%CF_secret is at plt_config.pl
=cut
our %CF_secret = %PltConf::CF_secret;
our %CF = (
  %CF_secret,
  NOW_CMD      => 'date "+%Y-%m-%d_%H-%M-%S"',
  DAYS_AGO     => '{{p_days_ago}} days ago',
  DATE_STR_CMD => "date --date '{{DAYS_AGO}}'",
);
# printArgs();
# loading variables from configuration
# print "CF1: \n" .Dumper(\%CF). "\n";

%CF = PltConf::fill_CF(\%CF, \%arg);
no warnings 'once';
%SPlt::CF_secret = %CF_secret;
no warnings 'once';
%SPlt::CF = %CF;

# print "arg: \n" .Dumper(\%arg). "\n";
# print "CF2: \n" .Dumper(\%CF). "\n";

# our %WHERE = %SPlt::CF_secret;

# print "WHERE: \n" . Dummper(\%WHERE) . "\n";

$arg{help} and help();
$arg{print_args} and SPlt::print_args();
$arg{print_config} and SPlt::print_config();
$arg{print_status} and SPlt::print_status();

########################################################################
# Support subroutines
########################################################################

sub help {
  Log(SPlt->HELP, "Usage: $0 configfile [options]\n");
  Log(SPlt->HELP, "    TODO\n");
  Log(SPlt->HELP, "    For full documentation, please visit:\n");
  Log(SPlt->HELP, "    http://some_host\n");
  exit 0;
}

=pod
This subroutine is a shortcut for executing commands
=cut
sub ex {
  my ($msg, $cmd, $type, $ignore_dry);
  $type = 0;
  no warnings 'once';
  my $where = $PltConf::CF_secret{RUN_AS};

  my $cmd_type = SPlt->CMD;
  $ignore_dry = "";
  if (scalar(@_) > 4) {
    ($msg, $where, $cmd, $type, $ignore_dry) = @_;
  } elsif (scalar(@_) > 3) {
    ($msg, $where, $cmd, $type) = @_;
  } elsif (scalar(@_) > 2) {
    my ($a, $b, $ignore_dry_try) = @_; # TODO clean
    if ($ignore_dry_try eq SPlt->IGNORE_DRY) {
      ($msg, $cmd, $ignore_dry) = @_;
    } else {
      ($msg, $where, $cmd) = @_;
    }
  } else {
    ($msg, $cmd) = @_;
  }
  if ($type eq "system") {
    $cmd_type = SPlt->CMD_SYS;
  }
  if ($ignore_dry ne "") {
    return Log($cmd_type, $msg, $cmd, $ignore_dry . "$where|");
  } else {
    return Log($cmd_type, $msg, $cmd, "$where|");
  }
}

=pod
This subroutine is used in conditions to decide what should be executed
=cut
sub should {
  my ($a, $expected, $log_as);
  $log_as = SPlt->INFO_BLOCK;
  $expected = 1;
  if (scalar(@_) > 2) {
    ($a, $expected, $log_as) = @_;
  } elsif (scalar(@_) > 1) {
    ($a, $expected) = @_;
  } else {
    ($a) = @_;
  }
  # Log(SPlt->INFO, "\$a: $a\n");
  if (not (defined $expected || $expected eq "")) {
    $expected = 1;
  }
  Log($log_as, "$a: expected: $expected, actual: $arg{$a} \n");
  if ($arg{$a} eq $expected) {
    return 1;
  } else {
    return 0;
  }
}

########################################################################
# Examples, TODO (re)move
########################################################################

=pod
This example shows usage of hash variable CF_
- prints current date
- prints date 5 days ago
=cut
sub example_args {
  Log(SPlt->INFO_BLOCK, "example_args - start\n");
  Log(SPlt->INFO, "Command line arguments are propagated to \%CF:\n" . Dumper(\%CF) . "");
  my $res = ex("Executes this script with argument that changes configuration",
    "cd $cur_dir ; ./main.pl --print_args --print_config --p_days_ago=10", SPlt->IGNORE_DRY);
  Log(SPlt->INFO, "example_args: \$res:\n" . Dumper(\$res) . "\n");
  Log(SPlt->INFO_BLOCK, "example_args - end\n");
}

=pod
This example shows usage of hash variable CF_
- prints current date
- prints date 5 days ago
=cut
sub example_cmd_exec {
  Log(SPlt->INFO_BLOCK, "example_cmd_exec - start\n");

  Log(SPlt->INFO, "Result: " . Dumper(Log(SPlt->CMD, "#1 Example cmd", "echo test")) . "");
  Log(SPlt->INFO, "Result: " . Dumper(Log(SPlt->CMD, "#2 Example cmd", "echo test", SPlt->IGNORE_DRY)) . "");
  my $res_data;
  Log(SPlt->INFO, "Return code: " . Log(SPlt->CMD, "#3 Example cmd", "echo test", SPlt->IGNORE_DRY . SPlt->RC_AS_RES, \$res_data) . "\n");
  Log(SPlt->INFO, "Result: " . Dumper($res_data));
  Log(SPlt->INFO, "Result: " . Dumper(Log(SPlt->CMD, "#4.1 Example cmd", "unknownCommand", SPlt->IGNORE_DRY)) . "");
  Log(SPlt->INFO, "Result: " . Dumper(Log(SPlt->CMD, "#4.2 Example cmd", "unknownCommand", SPlt->IGNORE_DRY . SPlt->FORCE_OK)) . "");
  Log(SPlt->INFO, "Result: " . Dumper(Log(SPlt->CMD_BASH, "#4.3 Example cmd", "unknownCommand", SPlt->IGNORE_DRY)) . "");
  Log(SPlt->INFO, "Result: " . Dumper(Log(SPlt->CMD_PLAIN, "#4.4 Example cmd", "unknownCommand", SPlt->IGNORE_DRY)) . "");
  Log(SPlt->INFO, "Result: " . Dumper(Log(SPlt->CMD_EXEC, "#4.5 Example cmd", "unknownCommand", SPlt->IGNORE_DRY)) . "");
  Log(SPlt->INFO, "Return code: " . Log(SPlt->CMD, "#5 Example cmd", "echo test",
    SPlt->LOCAL . SPlt->RC_AS_RES . SPlt->IGNORE_DRY . SPlt->FORCE_OK, \$res_data) . "\n");
  Log(SPlt->INFO, "Result: " . Dumper($res_data));

  Log(SPlt->INFO_BLOCK, "example_cmd_exec - end\n");
}

=pod
This example shows usage of CF_
- prints current date
- prints date 5 days ago
=cut
sub example_should_ex {
  Log(SPlt->INFO_BLOCK, "example_should_ex - start\n");
  if (should("example_should_ex1") || should("examples_all")) {
    my $noResult = ex("Get current time #1", "$CF{NOW_CMD}");
    Log(SPlt->INFO, "\$noResult:\n" . Dumper($noResult) . "");
    my $result = ex("Get current time #1 - SPlt->IGNORE_DRY", "$CF{NOW_CMD}", SPlt->IGNORE_DRY);
    chomp $result;
    Log(SPlt->INFO, "\$result:\n" . Dumper($result) . "");
  }
  if (should("example_should_ex2", 0) || should("examples_all")) {
    ex("Print TODO message", "echo 'TODO: preparing environment'");
    my $result = ex("Get current time", "$CF{NOW_CMD}");
    Log(SPlt->INFO, "\$result:\n" . Dumper($result) . "\n");
  }
  if (should("example_should_ex2", 0, SPlt->NONE) || should("examples_all")) {
    ex("Print #2 TODO message", "echo 'TODO: preparing #2 environment'");
    Log(SPlt->INFO, "\$result:\n" . Dumper(ex("Get current time", "$CF{NOW_CMD}", SPlt->IGNORE_DRY)) . "");
  }
  Log(SPlt->INFO_BLOCK, "example_should_ex - end\n");
}

=pod
This example shows usage of printing spaced blocks,
History: I used this for easier reading of logs (not much useful with huge number of log messages)
=cut
sub example_block_spacing {
  Log(SPlt->INFO_BLOCK_START, "example_block_spacing - start\n");
  my $textData = Dumper(ex("Get current time", "$CF{NOW_CMD}", SPlt->IGNORE_DRY));
  Log(SPlt->INFO, "\$result:\n" . SPlt::prefix_var($textData) . "");
  Log(SPlt->INFO_BLOCK_START, "example_block_spacing_2\n");
  Log(SPlt->INFO, "Some other log with Dumper:\n" . SPlt::prefix_var($textData) . "");
  Log(SPlt->INFO_BLOCK_START, "example_block_spacing_3\n");
  Log(SPlt->INFO, "Some other log with Dumper:\n" . SPlt::prefix_var($textData) . "");
  Log(SPlt->INFO_BLOCK_END, "example_block_spacing_3\n");
  Log(SPlt->INFO_BLOCK_END, "example_block_spacing_2\n");
  Log(SPlt->INFO_BLOCK_END, "example_block_spacing - end\n");
}

sub examples {
  example_should_ex();
  example_cmd_exec() if should("example_cmd_exec") || should("examples_all");
  example_args() if should("example_args") || should("examples_all");
  example_block_spacing() if should("example_block_spacing") || should("examples_all");
}

########################################################################
# Main, TODO code
########################################################################

sub main {
  Log(SPlt->INFO, "Started\n");
  examples() if (should("examples", 1, SPlt->NONE) || should("examples_all", 1, SPlt->NONE));
  Log(SPlt->INFO, "Finished\n");
}

main();
