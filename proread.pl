#!/usr/bin/perl -w

#
# proread.pl:
#
# Utility to read a file out of an Apple II ProDOS .po disk image.
#
# 20190116 LSH
#

use strict;

use ProDOS;

#my $mode = 'T';  # T=Text
my $mode = 'B';  # B=Binary
#my $conv = 1;  # Convert \r to \n
my $conv = 0;  # Don't convert \r to \n
my $text_conv = 0;  # Don't clear high bit
my $debug = 0;

while (defined $ARGV[0] && $ARGV[0] =~ /^-/) {
  # Mode
  if ($ARGV[0] eq '-m' && defined $ARGV[1] && $ARGV[1] ne '') {
    # Text
    if ($ARGV[1] eq 'T') {
      $mode = 'T';
      $conv = 1;
    # Integer BASIC
    } elsif ($ARGV[1] eq 'I') {
      $mode = 'I';
      $conv = 0;
    # Applesoft
    } elsif ($ARGV[1] eq 'A') {
      $mode = 'A';
      $conv = 0;
    # Binary
    } elsif ($ARGV[1] eq 'B') {
      $mode = 'B';
      $conv = 0;
    # S
    } elsif ($ARGV[1] eq 'S') {
      $mode = 'S';
      $conv = 0;
    } else {
      die "Unknown mode for -m, must be T, I, A, B or S\n";
    }
    shift;
    shift;
  # Convert (carriage return to linefeed)
  } elsif ($ARGV[0] eq '-c') {
    $conv = 1;
    shift;
  # Text convert (clear high bit)
  } elsif ($ARGV[0] eq '-t') {
    $text_conv = 1;
    shift;
  # Debug
  } elsif ($ARGV[0] eq '-d') {
    $debug = 1;
    shift;
  } else {
    die "Unknown command line argument $ARGV[0]\n";
  }
}

my $pofile = shift or die "Must supply .po filename\n";
my $filename = shift or die "Must supply filename (on disk image)\n";
my $output_file = shift;

read_file($pofile, $filename, $mode, $conv, $text_conv, $output_file, $debug);

1;

