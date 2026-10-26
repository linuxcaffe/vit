# Copyright 2012 - 2013, Steve Rader
# Copyright 2013 - 2018, Scott Kostyshak

sub parse_args {
  while ( @ARGV ) {
    if ( $ARGV[0] eq '--help' || $ARGV[0] eq '-help' || $ARGV[0] eq '-h' ) {
      &usage();
    }
    if ( $ARGV[0] eq '--version' || $ARGV[0] eq '-version' || $ARGV[0] eq '-v' ) {
      print "$version\n";
      exit 0;
    }
    if ( $ARGV[0] eq '--audit' || $ARGV[0] eq '-audit' || $ARGV[0] eq '-a' ) {
      $audit = 1;
      shift @ARGV;
      next;
    }
    if ( $ARGV[0] eq '--titlebar' || $ARGV[0] eq '-titlebar' || $ARGV[0] eq '-t' ) {
      $titlebar = 1;
      shift @ARGV;
      next;
    }
    $cli_args .= &quote_args($ARGV[0]) . ' ';
    shift @ARGV;
    next;
  }
  if ( $audit ) {
    my $dir = ( $ENV{'XDG_RUNTIME_DIR'} || "$ENV{'HOME'}/.cache" ) . '/vit';
    make_path($dir);
    $audit_file = "$dir/vit_audit.log";
    open(AUDIT, ">", $audit_file) or die "$audit_file: $!";
    open STDERR, '>&AUDIT';

    # flush AUDIT after printing to it
    my $ofh = select AUDIT;
    $| = 1;
    select $ofh;

    print AUDIT "$$ INIT $0 " . join(' ',@ARGV), "\r\n";
  }
}

#------------------------------------------------------------------

sub usage {
  print "usage: vit [switches] [task_args]\n";
  print "  -audit     log task commands to \$XDG_RUNTIME_DIR/vit/vit_audit.log\n";
  print "             (~/.cache/vit/ without XDG_RUNTIME_DIR)\n";
  print "  -titlebar  sets the xterm titlebar to \"$version\"\n";
  print "  -version  prints the version\n";
  print "  task_args  any set of task commandline args that print an \"ID\" column\n";
  exit 0;
}

return 1;

