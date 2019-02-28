#!/usr/bin/perl -w

#
# prorename.pl:
#
# Utility to rename a file on an Apple II ProDOS .po disk image.
#
# 20190228 LSH
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
my $new_filename = shift or die "Must supply new filename (on disk image)\n";

rename_file($pofile, $filename, $new_filename, $debug);

1;

