#!/usr/bin/perl -w

#
# proundelete.pl:
#
# Utility to undelete a file on an Apple II ProDOS .po disk image.
#
# 20190308 LSH
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
my $filename = shift or die "Must supply filename (on disk image)\n";

undelete_file($pofile, $filename, $debug);

1;

