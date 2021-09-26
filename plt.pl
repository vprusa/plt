#!/usr/bin/perl -w
# -*-mode:cperl -*-

########################################################################
# Perl Logging Tool
# Author: Vojtech Prusa (prusa.vojtech@gmail.com), 2021
########################################################################
package SPlt;

use strict;
use warnings;
use experimental 'smartmatch';
use Data::Dumper qw(Dumper);

# https://metacpan.org/pod/experimental
use experimental 'lexical_subs', 'smartmatch';

use 5.016003; # current version

use POSIX qw/floor/;
use File::Basename;
use Cwd 'abs_path';
use Getopt::Long qw(GetOptions);

my $cur_dir = dirname(abs_path($0));
my $conf_path = $cur_dir . '/plt_config.pl';
require $conf_path;

our ${prefix_ws_nmb} = 0;
our %arg;

=pod
History:
In one of the projects the development was not optimal and I was not given proper access to machine so I had to
execute parts of the code on one of the localhost and several machines. Doable but terrible.
=cut
our %WHERE = (
  LOCAL => "LOCAL",
  TEST  => "TEST",
  SHARP => "SHARP",
);

########################################################################
use Data::Dumper qw(Dumper);
# TODO load from main.pl
our %CF_secret = %Plt::CF_secret;
our %CF = (%CF_secret);

# print "plt.pl::CF: \n" . Dumper(\%CF);
# print "plt.pl::CF_secret: \n" . Dumper(\%CF_secret);

=pod
Constants to decide what and how to print, execute and skip (color and conditions)
=cut
use constant {
  # => '',
  INFO             => 'INFO',             # Info message
  INFO_G           => 'INFO_G',           # Info with glow
  INFO_BLOCK       => 'INFO_BLOCK',       # Info with block glow, used with 'should()' to distinguish what is and is not executed
  INFO_BLOCK_START => 'INFO_BLOCK_START', # TODO adds spaces more leading spaces of following printed logs
  INFO_BLOCK_END   => 'INFO_BLOCK_END',   # TODO removes spaces leading spaces of following printed logs
  ARGS             => 'ARGS',             # Used for printing arguments
  HELP             => 'HELP',             # Used for printing help
  CMD              => 'CMD',              # Execute command (and result is stored via optional pointer)
  CMD_SYS          => 'CMD_SYS',          # Execute command with system($cmd)
  CMD_EXEC         => 'CMD_EXEC',         # Execute command with exec($cmd)
  CMD_BASH         => 'CMD_BASH',         # Execute command with `/bin/bash -c '$cmd'`
  CMD_PLAIN        => 'CMD_PLAIN',        # Execute command with `$cmd'`
  NOTE             => 'NOTE',             # Note message - less important than INFO
  NONE             => 'NONE',             # Do not print
  WARN             => 'WARN',             # Print as Warning (yellow)
  ERR              => 'ERR',              # Print as Error (red)
  DEB              => 'DEB',              # Debug messages (non-white)
  DEB_SKIP         => 'DEB_SKIP',         # If it should be skipped when $debug != 1
  DEB_DONT_SKIP    => 'DEB_DONT_SKIP',    # If it should NOT be skipped even when $debug != 1
  # flags
  IGNORE_DRY       => 'IGNORE_DRY|', # flag, used to ignore dry runs (useful in some cases when command is read-only)
  RC_AS_RES        => 'RC_AS_RES|',  # flag, returns commands return code as result
  FORCE_OK         => 'FORCE_OK|',   # flag, force CMD to 'Result: OK-Forced' regardless success of command execution
  LOCAL            => 'LOCAL|',      # flag, executes locally regardles of $where
};
# TODO if many other flags will be used put them to separately defined constant block

=pod
Commend what is not wanted, necessary or obsolete
Commenting top level will not skip printing uncommented lower levels
Make sure that prefixes (before '_' delimiter) are unique
E.g.:
my @SHOULD_LOG = (
  # DEB,
  # DEB_SKIP,
  DEB_DONT_SKIP,
}
will print DEB_DONT_SKIP
will NOT print DEB, DEB_SKIP
=cut
my @SHOULD_LOG = (
  INFO, WARN, ERR, ARGS, HELP,
  INFO_BLOCK, INFO_BLOCK_START, INFO_BLOCK_END,
  CMD, CMD_SYS, CMD_EXEC, CMD_BASH, CMD_PLAIN,
  # DEB,
  # DEB_SKIP,
  DEB_DONT_SKIP,
);

=pod
Choose which messages log as strings and which objects using Dumper
=cut
# my @SHOULD_LOG_STR = @SHOULD_LOG; # log all as string
my @SHOULD_LOG_STR = (
  INFO, WARN, ERR, ARGS, HELP,
  INFO_BLOCK, INFO_BLOCK_START, INFO_BLOCK_END,
  CMD, CMD_SYS, CMD_EXEC, CMD_BASH, CMD_PLAIN,
  # DEB,
  # DEB_SKIP,
  DEB_DONT_SKIP,
);

use Term::ANSIColor qw(:constants);
=pod
Log coloring
https://metacpan.org/pod/Term::ANSIColor

The recognized normal foreground color attributes (colors 0 to 7) are:
black  red  green  yellow  blue  magenta  cyan  white

The corresponding bright foreground color attributes (colors 8 to 15) are:
bright_black  bright_red      bright_green  bright_yellow
bright_blue   bright_magenta  bright_cyan   bright_white

The recognized normal background color attributes (colors 0 to 7) are:
on_black  on_red      on_green  on yellow
on_blue   on_magenta  on_cyan   on_white

The recognized bright background color attributes (colors 8 to 15) are:
on_bright_black  on_bright_red      on_bright_green  on_bright_yellow
on_bright_blue   on_bright_magenta  on_bright_cyan   on_bright_white

=cut
sub color {
  my ($name) = @_;
  my @prefix = split("_", $name);
  if ($name ~~ INFO || $name ~~ CMD || $name ~~ CMD_SYS || $name ~~ CMD_EXEC) {
    print WHITE, $name . ": ", RESET;
    # print $name . ": ";
  } elsif ($name ~~ WARN) {
    print YELLOW, $name . ": ", RESET;
    # print , $name . ": ", RESET;
  } elsif ($name ~~ ERR) {
    print RED, $name . ": ", RESET;
  } elsif ($name ~~ INFO_BLOCK || $name ~~ INFO_BLOCK_START || $name ~~ INFO_BLOCK_END) {
    print ON_GREEN, $name . ":", RESET, " ";
  } elsif ($name ~~ INFO_G) {
    print ON_YELLOW, $name . ":", RESET, " ";
  } elsif ($name ~~ DEB || $prefix[0] ~~ DEB) {
    print MAGENTA, $name . ": ", RESET;
    # CYAN
  } else {
    print $name . ": ";
  }
}

=pod
Also possible to log debug messages to file
TODO change to array and log different message types to different files
=cut
our $debug_only_log_file_path = $SPlt::debug_only_log_file_path;
# print "\$SPlt::debug_only_log_file_path: $SPlt::debug_only_log_file_path";
# print "\$debug_only_log_file_path: $debug_only_log_file_path";

our $dry = 1;
sub set_dry {
  my ($a) = @_;
  $dry = $a;
}

sub get_dry {
  return $dry;
}

=pod
TODO
Code generation...
Store generated code to file...
# my $ONLY_CMD = 0;
=cut

=pod
Subroutine for logging, execution, etc.

INFO:
    Log($type, $msg)

CMD:
    Log($type, $msg, $cmd[, $flags][, $data])

g.e.:
    ```
    my $res_data = Log(SPlt->CMD, "Example cmd", "echo test");
    ```
    ```
    my $res_data = Log(SPlt->CMD, "Example cmd", "echo test", SPlt->IGNORE_DRY);
    ```
    ```
    my $res_data = Log(SPlt->CMD, "Example cmd", "echo test", SPlt->IGNORE_DRY);
    my $res_data2 = Log(SPlt->CMD, "Example cmd", "unknownCommand", SPlt->FORCE_OK . SPlt->IGNORE_DRY);
    ```
    ```
    my $res_data;
    my $return_code = Log(SPlt->CMD, "Example cmd", "echo test", SPlt->IGNORE_DRY . SPlt->RC_AS_RES, \$res_data);
    ```
    ```
     my $res_data;
     my $return_code = Log(SPlt->CMD, "Example cmd", "echo test",
      SPlt->LOCAL . SPlt->RC_AS_RES . SPlt->IGNORE_DRY. SPlt->FORCE_OK, \$res_data);
    ```
    ```
    my $res_data;
    my $return_code = Log(SPlt->CMD, "Example cmd", "echo test",
      SPlt->LOCAL . SPlt->RC_AS_RES . SPlt->IGNORE_DRY. SPlt->FORCE_OK . "$WHERE{TEST}|$WHERE{SHARP}", \$res_data);
    ```
=cut
sub Log {
  my ($type, $msg, $where, @val);
  my %CF = %PltConf::CF_secret;
  # $where = $WHERE{LOCAL};
  $where = $CF{RUN_AS};
  if (scalar(@_) > 1) {
    ($type, @val) = @_;
  }
  my ${prefix_ws} = get_prefix_space();
  if (scalar(@_) > 1) {
    my @prefix = split("_", $type);

    if ($type ~~ @SHOULD_LOG || $prefix[0] ~~ @SHOULD_LOG) {
      if ($type ~~ INFO_BLOCK_START) {
        ${prefix_ws_nmb}++;
        ${prefix_ws} = get_prefix_space();
      } elsif ($type ~~ INFO_BLOCK_END) {
        ${prefix_ws_nmb}--;
        ${prefix_ws} = get_prefix_space();
      }
      if ($type ~~ DEB || $prefix[0] ~~ DEB) {
        color $type;
        open(SOUBOR, ">> $debug_only_log_file_path");
        print SOUBOR $type . ": ";
        print SOUBOR @val;
        close(SOUBOR);
        print @val;
      } elsif ($prefix[0] ~~ CMD) {
        my $res;
        ($type, $msg, @val) = @_;
        if (@val) {
          my $cmd = $val[0];
          my $opts = 0;
          if (exists($val[1])) {
            $opts = $val[1];
            # print "Opts: $opts\n";
          }
          my $wholeCmd = $cmd;
          # TODO generalize concept of executing remotely
          if ($where ~~ $WHERE{TEST}) {
            $wholeCmd = $CF{SSH_TEST} . " '" . qq($cmd) . "'";
          } elsif ($where ~~ $WHERE{SHARP}) {
            $wholeCmd = $CF{SSH_SHARP} . " '" . qq($cmd) . "'";
          } else {
            # exec locally
          }
          $cmd = $wholeCmd; # TODO rename
          print ${prefix_ws};
          color $type;
          print $msg;
          print " [Opts($opts)]:" if(defined $CF{PRINT_OPTS} && $CF{PRINT_OPTS} == 1);
          print YELLOW;
          print "\n${prefix_ws}$CF{PRINT_WS}" . $cmd . "\n";
          print WHITE;
          # decides how to executes cmd and executes it
          if ($dry eq 0 || ($opts =~ IGNORE_DRY)) {

            print "${prefix_ws}$CF{PRINT_WS}Result: ", RESET if(defined $CF{PRINT_RESULT} && $CF{PRINT_RESULT} == 1);

            print RESET;
            # execute command
            if ($type =~ CMD_SYS) {
              system($cmd);
            } elsif ($type =~ CMD_EXEC) {
              exec($cmd);
            } elsif ($type =~ CMD_BASH) {
              $res = `/bin/bash -c '${cmd}'`;
            } elsif ($type =~ CMD_PLAIN) {
              # may return nonsense on g.e. unknownCommand
              $res = `${cmd}`;
            } else {
              # $res = `/bin/bash -c '${cmd}'`;
              $res = `${cmd}`;
            }

            if (defined $res && $res ne '' && (defined $CF{PRINT_RESULT} && $CF{PRINT_RESULT} == 1)) {
              chomp $res;
              print $res;
              print "\n";
            }

            #deal with return code
            my $ec = $? >> 8;
            if ($opts =~ m/RC_AS_RES/) {
              # return result via ptr and result set to return code
              @val[2] = $res;
              $res = $ec;
            } else {
              # TODO idk, maybe if possible
              # @val[2] = $ec if(scalar(@val) > 2);
            }

            if(defined $CF{PRINT_ERROR_CODE} && $CF{PRINT_ERROR_CODE} == 1) {
              print "${prefix_ws}$CF{PRINT_WS}", WHITE, "EC: ", RESET;
              print $ec, "\n";
            }

            print "${prefix_ws}$CF{PRINT_WS}", WHITE, "Status: ", RESET;

            # deal with returning data, return code, logging return status and printing it
            if ($opts =~ m/FORCE_OK/) {
              print "OK-FORCED\n", RESET;
            } else {
              if ($ec == 0) {
                if ($prefix[0] ~~ m/CMD/) {
                  print "${prefix_ws}OK\n";
                } else {
                  print "$res\n";
                }
              }
              if ($ec != 0) {print ${prefix_ws}, "", RED, "KO\n", RESET;}
            }
          } else {
            print "DRY\n";
          }
        }
        print RESET;
        # print Dumper($res);
        chomp $res if (defined $res && $res ne '');
        return $res;
      } else {
        # print "$type ";
        print ${prefix_ws};
        color $type;
        if ($type ~~ @SHOULD_LOG_STR || $prefix[0] ~~ @SHOULD_LOG_STR) {
          # TODO ...
          # my $valStr = (@val);
          # $valStr =~ s/\\n/${prefix_ws}\\n/g;
          # foreach my $valLine (@val) {
          #   print "${prefix_ws}$valLine";
          # }
          print "@val";
        } else {
          print ${prefix_ws} . Dumper(@val);
        }
      }
    }
  } else {
    # TODO print only if second argument is not empty, because if it is empty this is still
    # executed even when it should not pass "scalar(@_) > 1"
    print ${prefix_ws} . Dumper(@_);
  }
}

=pod
Get spaces for prefix,
see INFO_BLOCK_START and INFO_BLOCK_END
=cut
sub get_prefix_space {
  # return '    ' x ${prefix_ws_nmb};
  my %CF = %PltConf::CF_secret;
  # print "CF:\n" . Dumper(\%CF) ."\n";
  return $CF{PREFIX_BLOCK_WS} x ${prefix_ws_nmb};
}

=pod
Consumes variable (like Dumper result),
plt_prefix_var(Dumper($var)),
see INFO_BLOCK_START and INFO_BLOCK_END
=cut
sub prefix_var {
  my $text = "";
  my $prefix = get_prefix_space();
  foreach my $line (@_) {
    $text .= "$prefix  $line\n";
  }
  chomp $text;
  return $text;
}

sub print_sorted_hash {
  my %hash = @_;
  my $out = "";
  foreach my $name (sort keys %hash) {
    $out .= "    '$name' => $hash{$name},\n";
  }
  return $out;
}
sub print_status {
  # Log(INFO, "Sharp(0): $devel, debug(1): $debug, cur_dir: $cur_dir\n");
  my %CF = %PltConf::CF_secret;
  Log(INFO, "Sharp(0): $CF{DEVEL}, debug(1): $CF{DEBUG}, cur_dir: $cur_dir\n");
}

sub print_args {
  Log(ARGS, "ARG ARRAY => \n" . print_sorted_hash(%main::arg) . "\n");
}

sub print_config {
  Log(ARGS, "ARG \%CF_secret => \n" . print_sorted_hash(%SPlt::CF_secret) . "\n");
  Log(ARGS, "ARG \%CF => \n" . print_sorted_hash(%SPlt::CF) . "\n");
}
package main;

# Wrapper for case when you do not want to call SPlt::Log() but Log() because type speed matters
sub Log {
  SPlt::Log(@_);
}
