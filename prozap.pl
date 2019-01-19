#!/usr/bin/perl -w

#
# prozap.pl:
#
# Utility to edit a ProDOS block (.PO image).
#
# 20190115 LSH
#

use strict;

use PO;

my $debug = 0;

my $blk = -1;
my $dst_blk = -1;
my $write = 0;

my @mods = ();

while (defined $ARGV[0] && $ARGV[0] =~ /^-/) {
  # Debug
  if ($ARGV[0] eq '-d') {
    $debug = 1;
    shift;
  # Block to read
  } elsif ($ARGV[0] eq '-b' && defined $ARGV[1] && $ARGV[1] =~ /^\d+$/) {
    $blk = $ARGV[1];
    shift;
    shift;
  # Destination block
  } elsif ($ARGV[0] eq '-db' && defined $ARGV[1] && $ARGV[1] =~ /^\d+$/) {
    $dst_blk = $ARGV[1];
    shift;
    shift;
  # Allow modifying data.
  } elsif ($ARGV[0] =~ /^-m([ahA])/ && defined $ARGV[1] && $ARGV[1] ne '') {
    my $typ = $1;
    print "$ARGV[1] typ=$typ\n" if $debug;
    if ($ARGV[1] =~ /^([0-9a-fA-F]+):\s*(.+)$/) {
      print "1=$1 2=$2\n" if $debug;
      push @mods, { 'typ' => $typ, 'addr' => $1, 'vals' => $2 };
    }
    shift;
    shift;
  } elsif ($ARGV[0] eq "-w") {
    $write = 1;
    shift;
  } else {
    die "Unknown command line argument $ARGV[0]\n";
  }
}

my $pofile = shift or die "Must supply .po filename\n";
die "Must supply block number 0-280\n" unless $blk >= 0 && $blk <= 280;

$dst_blk = $blk unless $dst_blk >= 0;

my $buf;

# Read the block
if (read_blk($pofile, $blk, \$buf)) {
  # Display the data in the block.
  dump_blk($buf);

  # Allow modifying the data.
  if ($write) {
    print "WRITING $dst_blk\n" if $debug;
    # Unpack the data in the block
    my @bytes = unpack "C512", $buf;

    # Process each modification.
    foreach my $mod (@mods) {
      my @mbytes = ();
      if ($mod->{'typ'} eq 'a') {
        print "ASCII vals=$mod->{'vals'}\n" if $debug;
        # Normal ASCII
        @mbytes = map { pack('C', ord($_)) } ($mod->{'vals'} =~ /(.)/g);
      } elsif ($mod->{'typ'} eq 'A') {
        print "HEX vals=$mod->{'vals'}\n" if $debug;
        # Apple II ASCII
        @mbytes = map { pack('C', ord($_) | 0x80) } ($mod->{'vals'} =~ /(.)/g);
      } elsif ($mod->{'typ'} eq 'h') {
        print "A2 ASCII vals=$mod->{'vals'}\n" if $debug;
        # HEX
        @mbytes = map { pack('C', hex(lc($_))) } ($mod->{'vals'} =~ /(..)/g);
      }
      my $addr = hex($mod->{'addr'});
      print "addr=$addr\n" if $debug;
      foreach my $byte (@mbytes) {
        print sprintf("byte=%02x\n", ord($byte)) if $debug;
        $bytes[$addr++] = ord($byte);
      }
    }

    # Re-pack the data in the block
    $buf = pack "C*", @bytes;

    # Write the destination block (default to block read).
    if (write_blk($pofile, $dst_blk, $buf)) {
      # Read the block back in.
      if (read_blk($pofile, $dst_blk, \$buf)) {
        # Display the data in the modified block.
        dump_blk($buf);
      } else {
        print "Failed final read!\n";
      }
    } else {
      print "Failed write!\n";
    }
  }
} else {
  print "Failed initial read!\n";
}

1;

