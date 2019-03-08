#!/usr/bin/perl -w

#
# proformat.pl:
#
# Utility to create a subdirectory on an Apple II ProDOS .po disk image.
#
# 20190308 LSH
#

use strict;

use ProDOS;

my $debug = 0;
my $blocks = 280;  # Default size of 5.25" floppy.
my $volume_name = 'NEWDISK';

while (defined $ARGV[0] && $ARGV[0] =~ /^-/) {
  # Debug
  if ($ARGV[0] eq '-d') {
    $debug = 1;
    shift;
  # Number of blocks for volume
  } elsif ($ARGV[0] eq '-b' && defined $ARGV[1] && $ARGV[1] =~ /^\d+$/) {
    $blocks = $ARGV[1];
    shift;
    shift;
  # Volume Name
  } elsif ($ARGV[0] eq '-v' && defined $ARGV[1] && $ARGV[1] =~ /^\S+$/) {
    $volume_name = substr($ARGV[1], 0, 15);
    shift;
    shift;
  } else {
    die "Unknown command line argument $ARGV[0]\n";
  }
}

my $pofile = shift or die "Must supply .po filename\n";

format_volume($pofile, $blocks, $volume_name, $debug);

1;

