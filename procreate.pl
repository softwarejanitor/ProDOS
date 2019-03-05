#!/usr/bin/perl -w

#
# procreate.pl:
#
# Utility to create a subdirectory on an Apple II ProDOS .po disk image.
#
# 20190305 LSH
#

use strict;

use ProDOS;

my $debug = 0;

while (defined $ARGV[0] && $ARGV[0] =~ /^-/) {
  # Debug
  if ($ARGV[0] eq '-d') {
    $debug = 1;
    shift;
  } else {
    die "Unknown command line argument $ARGV[0]\n";
  }
}

my $pofile = shift or die "Must supply .po filename\n";
my $subdirname = shift or die "Must supply subdirectory name (on disk image)\n";

create_subdir($pofile, $subdirname, $debug);

1;

