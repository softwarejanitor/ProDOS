#!/usr/bin/perl -w

#
# prowrite.pl:
#
# Utility to copy a file into an Apple II ProDOS .po disk image.
#
# 20190227 LSH
#

use strict;

use ProDOS;

my $filetype = 'TXT';  # Default to text file.
my $aux_type = undef;
my $mode = 'T';  # T=Text
my $conv = 1;  # Convert \r to \n
my $debug = 0;

while (defined $ARGV[0] && $ARGV[0] =~ /^-/) {
  # File type
  if ($ARGV[0] eq '-t' && defined $ARGV[1] && $ARGV[1] ne '') {
    $filetype = $ARGV[1];  # Checked in the module
    shift;
    shift;
  # Aux type
  } elsif ($ARGV[0] eq '-a' && defined $ARGV[1] && $ARGV[1] ne '') {
    $aux_type = $ARGV[1];  # Checked in the module
    shift;
    shift;
  # Mode
  } elsif ($ARGV[0] eq '-m' && defined $ARGV[1] && $ARGV[1] ne '') {
    # Text mode
    if ($ARGV[1] eq 'T') {
      $mode = 'T';
      $conv = 1;
    # Integer BASIC mode
    } elsif ($ARGV[1] eq 'I') {
      $mode = 'I';
      $conv = 0;
    # Applesoft mode
    } elsif ($ARGV[1] eq 'A') {
      $mode = 'A';
      $conv = 0;
    # Binary mode
    } elsif ($ARGV[1] eq 'B') {
      $mode = 'B';
      $conv = 0;
    # S mode
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
    $conv = 0;
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
my $filename = shift or die "Must supply filename (on local drive)\n";
my $apple_filename = shift or die "Must supply filename (on disk image)\n";

write_file($pofile, $filename, $mode, $conv, $apple_filename, $filetype, $aux_type, $debug);

1;

