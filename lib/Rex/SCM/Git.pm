package Rex::SCM::Git;

use strict;
use warnings;

# VERSION

use Cwd qw(getcwd);
use Rex::Commands::Fs;
use Rex::Helper::Run;
use File::Basename;
use Rex::Helper::Run;

use vars qw($CHECKOUT_BRANCH_COMMAND $CHECKOUT_TAG_COMMAND $CLONE_COMMAND);

$CLONE_COMMAND           = "git clone %s %s";
$CHECKOUT_BRANCH_COMMAND = "git checkout -b %s origin/%s";
$CHECKOUT_TAG_COMMAND    = "git checkout -b %s %s";

sub new {
  my $that  = shift;
  my $proto = ref($that) || $that;
  my $self  = {@_};

  bless( $self, $proto );

  return $self;
}

sub checkout {
  my ( $self, $repo_info, $checkout_to, $checkout_opt ) = @_;

  if ( !is_dir($checkout_to) ) {
    my $clone_cmd =
      sprintf( $CLONE_COMMAND, $repo_info->{"url"}, $checkout_to );
    Rex::Logger::debug("clone_cmd: $clone_cmd");

    Rex::Logger::info( "Cloning "
        . $repo_info->{"url"} . " to "
        . ( $checkout_to ? $checkout_to : "." ) );
    my $out = i_run "$clone_cmd", cwd => dirname($checkout_to);
    unless ( $? == 0 ) {
      Rex::Logger::info( "Error cloning repository.", "warn" );
      Rex::Logger::info($out);
      die("Error cloning repository.");
    }

    Rex::Logger::debug($out);

    if ( exists $checkout_opt->{"branch"} ) {
      unless ($checkout_to) {
        $checkout_to = [ split( /\//, $repo_info->{"url"} ) ]->[-1];
        $checkout_to =~ s/\.git$//;
      }

      my $checkout_cmd = sprintf(
        $CHECKOUT_BRANCH_COMMAND,
        $checkout_opt->{"branch"},
        $checkout_opt->{"branch"}
      );
      Rex::Logger::debug("checkout_cmd: $checkout_cmd");

      Rex::Logger::info( "Switching to branch " . $checkout_opt->{"branch"} );

      $out = i_run "$checkout_cmd", cwd => $checkout_to;
      unless ( $? == 0 ) {
        Rex::Logger::info( "Error switching to branch.", "warn" );
        Rex::Logger::info($out);
        die("Error switching to branch.");
      }
      Rex::Logger::debug($out);
    }

    if ( exists $checkout_opt->{"tag"} ) {
      my $checkout_cmd = sprintf(
        $CHECKOUT_TAG_COMMAND,
        $checkout_opt->{"tag"},
        $checkout_opt->{"tag"}
      );

      Rex::Logger::info( "Switching to tag " . $checkout_opt->{"tag"} );
      $out = i_run "$checkout_cmd", cwd => $checkout_to;
      unless ( $? == 0 ) {
        Rex::Logger::info( "Error switching to tag.", "warn" );
        Rex::Logger::info($out);
        die("Error switching to tag.");
      }
      Rex::Logger::debug($out);
    }
  }
  elsif ( is_dir("$checkout_to/.git") ) {
    my $branch = $checkout_opt->{"branch"} || "master";
    Rex::Logger::info( "Pulling "
        . $repo_info->{"url"} . " to "
        . ( $checkout_to ? $checkout_to : "." ) );

    my $rebase = $checkout_opt->{"rebase"} ? '--rebase' : '';
    my $out = i_run "git pull $rebase origin $branch", cwd => $checkout_to;

    unless ( $? == 0 ) {
      Rex::Logger::info( "Error pulling.", "warn" );
      Rex::Logger::info($out);
      die("Error pulling.");
    }
    else {
      Rex::Logger::debug($out);
    }

    if ( exists $checkout_opt->{"tag"} ) {
      my $tag = $checkout_opt->{tag};
      my $checkout_cmd = sprintf( $CHECKOUT_TAG_COMMAND, $tag, $tag );
      Rex::Logger::info( "Switching to tag " . $tag );
      $out = i_run "git fetch origin", cwd => $checkout_to;

      unless ( $? == 0 ) {
        Rex::Logger::info( "Error switching to tag.", "warn" );
        Rex::Logger::info($out);
        die("Error switching to tag.");
      }
      else {
        Rex::Logger::debug($out);
      }
      $out = i_run "$checkout_cmd", cwd => $checkout_to;
      unless ( $? == 0 ) {
        Rex::Logger::info( "Error switching to tag.", "warn" );
        Rex::Logger::info($out);
        die("Error switching to tag.");
      }
      Rex::Logger::debug($out);
    }
  }
  else {
    Rex::Logger::info( "Error checking out repository.", "warn" );
    die("Error checking out repository.");
  }
}

1;
