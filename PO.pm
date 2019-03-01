#!/usr/bin/perl -w

package PO;

#
# PO.pm:
#
# Module for low level access to Apple II .PO disk images (ProDOS Order)
#
# 20190115 LSH
#

use strict;

use Exporter::Auto;

my $debug = 0;

my $min_blk = 0;  # Minimum block number
my $max_blk = 280;  # Maximum block number
my $blk_size = 512;  # Block size

#
# Read entire .po image.
#
sub read_po {
  my ($pofile) = @_;

  my %po = ();

  my $dfh;

  if (open($dfh, "<$pofile")) {
    for (my $blk = 0; $blk <= $max_blk; $blk++) {
      my $bytes_read = read($dfh, $po{$blk}, $blk_size);
      if (defined $bytes_read && $bytes_read == $blk_size) {
        print '.';
      } else {
        print "\nError reading $blk\n";
      }
    }
    print "\n";
  } else {
    print "Unable to open $pofile\n";
  }

  return %po;
}

#
# Calculate position in .po file based on block.
#
sub calc_pos {
  my ($blk) = @_;

  my $pos = $blk * $blk_size;

  #print "pos=$pos\n";

  return $pos;
}

#
# Hex dump of block
#
sub dump_blk {
  my ($buf) = @_;

  my @bytes = unpack "C$blk_size", $buf;

  print "    ";
  for (my $c = 0; $c < 16; $c++) {
    print sprintf(" %1x ", $c);
  }
  print "\n";

  print "  +------------------------------------------------\n";

  for (my $r = 0; $r < 32; $r++) {
    print sprintf("%02x| ", $r);
    for (my $c = 0; $c < 16; $c++) {
      print sprintf("%02x ", $bytes[($r * 16) + $c]);
    }
    print "\n";
    print "  |";
    for (my $c = 0; $c < 16; $c++) {
      my $a = $bytes[($r * 16) + $c] & 0x7f;
      if (($a > 32) && ($a < 127)) {
        print sprintf(" %c ", $a);
      } else {
        print "   ";
      }
    }
    print "\n";
  }
  print "\n";
}

#
# Read block
#
sub read_blk {
  my ($pofile, $blk, $buf) = @_;

  #print "blk=$blk\n";

  my $dfh;

  my $pos = calc_pos($blk);

  if (open($dfh, "<$pofile")) {
    binmode $dfh;

    seek($dfh, $pos, 0);

    my $bytes_read = read($dfh, $$buf, $blk_size);

    close $dfh;

    if (defined $bytes_read && $bytes_read == $blk_size) {
      #print "bytes_read=$bytes_read\n";
      return 1;
    } else {
      print "Error reading $blk\n";
    }
  } else {
    print "Unable to open $pofile\n";
  }

  return 0;
}

sub clear_buf {
  my ($buf) = @_;

  $buf = pack "C*", 0x00 x 512;

  $_[0] = $buf;

  return $buf;
}

#
# Write Track/Sector
#
sub write_blk {
  my ($pofile, $blk, $buf) = @_;

  #print "blk=$blk\n";

  my $dfh;

  my $pos = calc_pos($blk);

  if (open($dfh, "+<$pofile")) {
    binmode $dfh;

    seek($dfh, $pos, 0);

    print $dfh $$buf;

    close $dfh;

    return 1;
  } else {
    print "Unable to write $pofile\n";
  }

  return 0;
}

1;

