#!/usr/bin/perl -w

package ProDOS;

#
# ProDOS.pm:
#
# Module to access Apple II ProDOS volumes.
#
# 20190115 LSH
#

use strict;

use POSIX;

use PO;

use Exporter::Auto;

my $debug = 0;

# For free space counts.
my %ones_count = (
  0x00 => 0,  # 0000
  0x01 => 1,  # 0001
  0x02 => 1,  # 0010
  0x03 => 2,  # 0011
  0x04 => 1,  # 0100
  0x05 => 2,  # 0101
  0x06 => 2,  # 0110
  0x07 => 3,  # 0111
  0x08 => 1,  # 1000
  0x09 => 2,  # 1001
  0x0a => 2,  # 1010
  0x0b => 3,  # 1011
  0x0c => 2,  # 1100
  0x0d => 3,  # 1101
  0x0e => 3,  # 1110
  0x0f => 4,  # 1111
);

# ProDOS file types
my %ftype = (
  # $0x Types: General

  # 00    Typeless file
  0x00 => '   ',
  # 01    BAD Bad block(s) file
  0x01 => 'BAD',
  # 04    TXT Text file (ASCII text, msb off)
  0x04 => 'TXT',
  # 06    BIN Binary file (8-bit binary image)
  0x06 => 'BIN',
  # 07    FNT Apple /// Font
  0x07 => 'FNT',
  # 08    FOT HiRes/Double HiRes Graphics
  0x08 => 'FOT',
  # 09    BA3 Apple III BASIC Program
  0x09 => 'BA3',
  # 0A    DA3 Apple III BASIC Data
  0x0a => 'DA3',
  # 0B    WPF Generic Word Processing
  0x0b => 'WPF',
  # 0C    SOS SOS System File
  0x0c => 'SOS',
  # f    DIR Directory file
  0x0f => 'DIR',

  # $1x Types: Productivity

  # 19    ADB AppleWorks data base file
  0x19 => 'ADB',
  # 1a    AWP AppleWorks word processing file
  0x1a => 'AWP',
  # 1b    ASP AppleWorks spreadsheet file
  0x1b => 'ASP',

  # $2x Types: Code

  # $20 TDM Desktop Manager File
  0x20 => 'TDM',
  # $21 IPS Instant Pascal Source
  0x21 => 'IPS',
  # $22 UPV UCSD Pascal Volume
  0x22 => 'UPV',
  # $29 3SD SOS Directory
  0x29 => '3SD',
  # $2A 8SC Source Code
  0x2a => '8SC',
  # $2B 8OB Object Code
  0x2b => '8OB',

  # $2C 8IC Interpreted Code
  0x2c => '8IC',
  #     $8003 - Apex Program File

  # $2D 8LD Language Data
  0x2d => '8LD',
  # $2E P8C ProDOS 8 Code Module
  0x2e => 'P8C',

  # $4x Types: Miscellaneous

  # $41 OCR Optical Character Recognition
  0x41 => 'OCR',
  # $42 FTD File Type Definitions
  0x42 => 'FTD',

  # $5x Types: Apple IIgs General

  # $50 GWP Apple IIgs Word Processing
  0x50 => 'GWP',
  #    $5445 - Teach
  #    $8001 - DeluxeWrite
  #    $8010 - AppleWorks GS

  # $51 GSS Apple IIgs Spreadsheet
  0x51 => 'GSS',
  #    $8010 - AppleWorks GS

  # $52 GDB Apple IIgs Database
  0x52 => 'GDB',
  #    $8010 - AppleWorks GS
  #    $8011 - AppleWorks GS Template
  #    $8013 - GSAS

  # $53 DRW Object Oriented Graphics
  0x53 => 'DRW',
  #    $8010 - AppleWorks GS

  # $54 GDP Apple IIgs Desktop Publishing
  0x54 => 'GDP',
  #    $8002 - GraphicWriter
  #    $8010 - AppleWorks GS

  # $55 HMD HyperMedia
  0x55 => 'HMD',
  #    $0001 - HyperCard GS
  #    $8001 - Tutor-Tech
  #    $8002 - HyperStudio
  #    $8003 - Nexus

  # $56 EDU Educational Program Data
  0x56 => 'EDU',
  # $57 STN Stationery
  0x57 => 'STN',
  # $58 HLP Help File
  0x58 => 'HLP',

  # $59 COM Communications
  0x59 => 'COM',
  #    $8010 - AppleWorks GS

  # $5A CFG Configuration
  0x5a => 'CFG',
  # $5B ANM Animation
  0x5b => 'ANM',
  # $5C MUM Multimedia
  0x5c => 'MUM',
  # $5D ENT Entertainment
  0x5d => 'ENT',
  # $5E DVU Development Utility
  0x5e => 'DVU',

  # $6x Types: PC Transporter

  # $60 PRE PC Pre-Boot
  0x60 => 'PRE',
  # $6B BIO PC BIOS
  0x6b => 'BIO',
  # $66 NCF ProDOS File Navigator Command File
  0x66 => 'NCF',
  # $6D DVR PC Driver
  0x6d => 'DVR',
  # $6E PRE PC Pre-Boot
  0x6e => 'PRE',
  # $6F HDV PC Hard Disk Image
  0x6f => 'HDV',

  # $7x Types: Kreative Software

  # $70 SN2 Sabine's Notebook 2.0
  0x70 => 'SN2',
  # $71 KMT
  0x71 => 'KMT',
  # $72 DSR
  0x72 => 'DSR',
  # $73 BAN
  0x73 => 'BAN',
  # $74 CG7
  0x74 => 'CG7',
  # $75 TNJ
  0x75 => 'TNJ',
  # $76 SA7
  0x76 => 'SA7',
  # $77 KES
  0x77 => 'KES',
  # $78 JAP
  0x78 => 'JAP',
  # $79 CSL
  0x79 => 'CSL',
  # $7A TME
  0x7a => 'TME',
  # $7B TLB
  0x7b => 'TLB',
  # $7C MR7
  0x7c => 'MR7',

  # $7D MLR Mika City
  0x7d => 'MLR',
  #    $005C - Script
  #    $C7AB - Color Table
  #    $CDEF - Character Definition

  # $7E MMM
  0x7e => 'MMM',
  # $7F JCP
  0x7f => 'JCP',

  # $8x Types: GEOS

  # $80 GES System File
  0x80 => 'GES',
  # $81 GEA Desk Accessory
  0x81 => 'GEA',
  # $82 GEO Application
  0x82 => 'GEO',
  # $83 GED Document
  0x83 => 'GED',
  # $84 GEF Font
  0x84 => 'GEF',
  # $85 GEP Printer Driver
  0x85 => 'GEP',
  # $86 GEI Input Driver
  0x86 => 'GEI',
  # $87 GEX Auxiliary Driver
  0x87 => 'GEX',
  # $89 GEV Swap File
  0x89 => 'GEV',
  # $8B GEC Clock Driver
  0x8b => 'GEC',
  # $8C GEK Interface Card Driver
  0x8c => 'GEK',
  # $8D GEW Formatting Data
  0x8d => 'GEW',

  # $Ax Types: Apple IIgs BASIC

  # $A0 WP  WordPerfect
  0xa0 => 'WP ',
  # $AB GSB Apple IIgs BASIC Program
  0xab => 'GSB',
  # $AC TDF Apple IIgs BASIC TDF
  0xac => 'TDF',
  # $AD BDF Apple IIgs BASIC Data
  0xad => 'BDF',

  # $Bx Types: Apple IIgs System

  # $B0 SRC Apple IIgs Source Code
  0xb0 => 'SRC',
  # $B1 OBJ Apple IIgs Object Code
  0xb1 => 'OBJ',
  # $B2 LIB Apple IIgs Library
  0xb2 => 'LIB',
  # $B3 S16 Apple IIgs Application Program
  0xb3 => 'S16',
  # $B4 RTL Apple IIgs Runtime Library
  0xb4 => 'RTL',
  # $B5 EXE Apple IIgs Shell Script
  0xb5 => 'EXE',
  # $B6 PIF Apple IIgs Permanent INIT
  0xb6 => 'PIF',
  # $B7 TIF Apple IIgs Temporary INIT
  0xb7 => 'TIF',
  # $B8 NDA Apple IIgs New Desk Accessory
  0xb8 => 'NDA',
  # $B9 CDA Apple IIgs Classic Desk Accessory
  0xb9 => 'CDA',
  # $BA TOL Apple IIgs Tool
  0xba => 'TOL',
  # $BB DRV Apple IIgs Device Driver
  0xbb => 'DRV',

  # $BC LDF Apple IIgs Generic Load File
  0xbc => 'LDF',
  #    $4001 - Nifty List Module
  #    $4002 - Super Info Module
  #    $4004 - Twilight Module
  #    $4083 - Marinetti Link Layer Module

  # $BD FST Apple IIgs File System Translator
  0xbd => 'FST',
  # $BF DOC Apple IIgs Document
  0xbf => 'DOC',

  # $Cx Types: Graphics

  # $C0 PNT Apple IIgs Packed Super HiRes
  0xc0 => 'PNT',
  #    $0001 - Packed Super HiRes
  #    $0002 - Apple Preferred Format
  #    $0003 - Packed QuickDraw II PICT

  # $C1 PIC Apple IIgs Super HiRes
  0xc1 => 'PIC',
  #    $0001 - QuickDraw PICT
  #    $0002 - Super HiRes 3200

  # $C2 ANI PaintWorks Animation
  0xc2 => 'ANI',
  # $C3 PAL PaintWorks Palette
  0xc3 => 'PAL',
  # $C5 OOG Object-Oriented Graphics
  0xc5 => 'OOG',
  # $C6 SCR Script
  0xc6 => 'SCR',
  # $C7 CDV Apple IIgs Control Panel
  0xc7 => 'CDV',

  # $C8 FON Apple IIgs Font
  0xc8 => 'FON',
  #    $0000 - QuickDraw Bitmap Font
  #    $0001 - Pointless TrueType Font

  # $C9 FND Apple IIgs Finder Data
  0xc9 => 'FND',
  # $CA ICN Apple IIgs Icon File
  0xca => 'ICN',

  # $Dx Types: Audio

  # $D5 MUS Music
  0xd5 => 'MUS',
  # $D6 INS Instrument
  0xd6 => 'INS',
  # $D7 MDI MIDI
  0xd7 => 'MDI',

  # $D8 SND Apple IIgs Audio
  0xd8 => 'SND',
  #    $0000 - AIFF
  #    $0001 - AIFF-C
  #    $0002 - ASIF Instrument
  #    $0003 - Sound Resource
  #    $0004 - MIDI Synth Wave
  #    $8001 - HyperStudio Sound

  # $DB DBM DB Master Document
  0xdb => 'DBM',

  # $Ex Types: Miscellaneous

  # $E0 LBR Archive
  0xe0 => 'LBR',
  #    $0000 - ALU
  #    $0001 - AppleSingle
  #    $0002 - AppleDouble Header
  #    $0003 - AppleDouble Data
  #    $8000 - Binary II
  #    $8001 - AppleLink ACU
  #    $8002 - ShrinkIt

  # $E2 ATK AppleTalk Data
  0xe2 => 'ATK',
  #    $FFFF - EasyMount Alias

  # $EE R16 EDASM 816 Relocatable Code
  0xee => 'R16',
  # ef    PAS ProDOS PASCAL file
  0xef => 'PAS',

  # $Fx Types: System

  # f0    CMD ProDOS added command file
  0xf0 => 'CMD',
  # f1-f8     User defined file types 1 through 8
  0xf1 => 'OVL',
  0xf2 => 'UD2',
  0xf3 => 'UD3',
  0xf4 => 'UD4',
  0xf5 => 'BAT',
  0xf6 => 'UD6',
  0xf7 => 'UD7',
  0xf8 => 'PRG',

  # $F9 P16 ProDOS-16 System File
  0xf9 => 'P16',

  # fa    INT Integer BASIC Program
  0xfa => 'INT',
  # fb    IVR Integer BASIC Variables
  0xfb => 'IVR',
  # fc    BAS Applesoft BASIC program file
  0xfc => 'BAS',
  # fd    VAR Applesoft stored variables file
  0xfd => 'VAR',
  # fe    REL Relocatable object module file (EDASM)
  0xfe => 'REL',
  # ff    SYS ProDOS system file
  0xff => 'SYS',
);

#
# Months for catalog date format.
#
my %months = (
   1, 'JAN',
   2, 'FEB',
   3, 'MAR',
   4, 'APR',
   5, 'MAY',
   6, 'JUN',
   7, 'JUL',
   8, 'AUG',
   9, 'SEP',
  10, 'OCT',
  11, 'NOV',
  12, 'DEC',
);

# Default key volume directory block.
my $key_vol_dir_blk = 2;

#
# Key Volume Directory Block
#
# 00-01 Previous Volume Directory Block
# 02-03 Next Volume Directory Block
#
# Volumne Directory Header
#
# 04    STORAGE_TYPE/NAME_LENGTH
#       fx where x is length of VOLUME_NAME
# 05-13 VOLUME_NAME
# 14-1b Not used
# 1c-1f CREATION
#       0-1 yyyyyyymmmmddddd  year/month/day
#       2-3 000hhhhh00mmmmmm  hours/minues
# 20    VERSION
# 21    MIN_VERSION
# 22    ACCESS
# 23    ENTRY_LENGTH
# 24    ENTRIES_PER_BLOCK
# 25-26 FILE_COUNT
# 27-28 BIT_MAP_POINTER
# 29-2a TOTAL_BLOCKS
#
my $key_vol_dir_blk_tmpl = 'vvCa15x8vvCCCCCvvva470';

my $vol_dir_blk_tmpl = 'vva504';

#
# Volume Bit Map
#
my $vol_bit_map_tmpl = 'C*';

#
# File Descriptive Entries
#
# 00    STORAGE_TYPE/NAME_LENGTH
#       0x Deleted entry. Available for reuse.
#       1x File is a seedling file (only one block)
#       2x File is a sapling file (2-256 blocks)
#       3x File is a tree file (257-32768 blocks)
#       dx File is a subdirectory
#       ex Reserved for Subdirectory Header entry
#       fx Reserved for Volume Directory Header entry
#          x is the length of FILE_NAME
# 01-0f FILE_NAME
# 10    FILE_TYPE
#       00        Typeless file
#       01    BAD Bad block(s) file
#       04    TXT Text file (ASCII text, msb off)
#       06    BIN Binary file (8-bit binary image)
#       0f    DIR Directory file
#       19    ADB AppleWorks data base file
#       1a    AWP AppleWorks word processing file
#       1b    ASP AppleWorks spreadsheet file
#       ef    PAS ProDOS PASCAL file
#       f0    CMD ProDOS added command file
#       f1-f8     User defined file types 1 through 8
#       fc    BAS Applesoft BASIC program file
#       fd    VAR Applesoft stored variables file
#       fe    REL Relocatable object module file (EDASM)
#       ff    SYS ProDOS system file
# 11-12 KEY_POINTER
# 13-14 BLOCKS_USED
# 15-17 EOF
# 18-1b CREATION
#       0-1 yyyyyyymmmmddddd  year/month/day
#       2-3 000hhhhh00mmmmmm  hours/minues
# 1c    VERSION
# 1d    MIN_VERSION
# 1e    ACCESS
#       80 File may be destroyed
#       40 File may be renamed
#       20 File has changed since last backup
#       02 File may be written to
#       01 File may be read
# 1f-20 AUX_TYPE
#       TXT Random access record length (L from OPEN)
#       BIN Load address for binary image (A from BSAVE)
#       BAS Load address for program image (when SAVEd)
#       VAR Address of compressed variables inmage (when STOREd)
#       SYS Load address for system program (usually $2000)
# 21-24 LAST_MOD
# 25-26 HEADER_POINTER
#
my $file_desc_ent_tmpl = 'Ca15Cvva3vvCCCvvvv';

my $key_dir_file_desc_ent_tmpl = '';
my $subdir_hdr_file_desc_ent_tmpl = '';
for (my $i = 0; $i < 12; $i++) {
  $key_dir_file_desc_ent_tmpl .= $file_desc_ent_tmpl;
  $subdir_hdr_file_desc_ent_tmpl .= $file_desc_ent_tmpl;
}

my $dir_file_desc_ent_tmpl = '';
my $subdir_file_desc_ent_tmpl = '';
for (my $i = 0; $i < 12; $i++) {
  $dir_file_desc_ent_tmpl .= $file_desc_ent_tmpl;
  $subdir_file_desc_ent_tmpl .= $file_desc_ent_tmpl;
}

#
# Subdirectory Header
#
# 00-01 Previous Subdirectory Block
# 02-03 Next Subdirectory Block
#
# 04    STORAGE_TYPE/NAME_LENGTH
#       ex where x is length of SUBDIR NAME
#
# 05-13 SUBDIR_NAME
# 14    Must contain $75
# 15-1b Reserved for future use
# 1c-1f CREATION
#       0-1 yyyyyyymmmmddddd  year/month/day
#       2-3 000hhhhh00mmmmmm  hours/minues
# 20    VERSION
# 21    MIN_VERSION
# 22    ACCESS
# 23    ENTRY_LENGTH
# 24    ENTRIES_PER_BLOCK
# 25-26 FILE_COUNT
# 27-28 PARENT_POINTER
# 29    PARENT_ENTRY
# 2a    PARENT_ENTRY_LENGTH
#
my $subdir_hdr_blk_tmpl = 'vvCa15Cx7vvCCCCCvvCCa469';

#
# Master Index Block (tree file)
#
my $master_ind_blk_lo_tmpl = 'C256';
my $master_ind_blk_hi_tmpl = 'x256C256';

#
# Index Block (tree file)
#
my $sub_ind_blk_lo_tmpl = 'C256';
my $sub_ind_blk_hi_tmpl = 'x256C256';

#
# Convert a ProDOS date to DD-MMM-YY string.
#
sub date_convert {
  my ($ymd, $hm) = @_;

  return "<NO DATE>" unless (defined $ymd && defined $hm && $ymd != 0);

  my $year = ($ymd & 0xfe00) >> 9;  # bits 9-15
  my $mon = ($ymd & 0x01e0) >> 5;  # bits 5-8
  my $day = $ymd & 0x001f;  # bits 0-4
  my $hour = ($hm & 0x1f00) >> 8;  # bits 8-12
  my $min = $hm & 0x003f;  # bits 0-5
  $mon = 0 if $mon > 12;

  return "<NO DATE>" if $mon < 1;

  return sprintf("%2d-%s-%02d %2d:%02d", $day, $months{$mon}, $year, $hour, $min);
}

# Parse Key Volume Directory Block
sub parse_key_vol_dir_blk {
  my ($buf, $mode, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volume_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, $dir_ents) = unpack $key_vol_dir_blk_tmpl, $buf;

  my $storage_type = ($storage_type_name_length & 0xf0) >> 4;
  my $name_length = $storage_type_name_length & 0x0f;

  my $volname = substr($volume_name, 0, $name_length);

  my @flds = unpack $key_dir_file_desc_ent_tmpl, $dir_ents;

  my @files = ();
  for (my $i = 0; $i < 12; $i++) {
    my $storage_type_name_length = shift @flds;
    my $storage_type = ($storage_type_name_length & 0xf0) >> 4;
    my $name_length = $storage_type_name_length & 0x0f;
    my $file_name = shift @flds;
    my $fname = substr($file_name, 0, $name_length);
    my $file_type = shift @flds;
    my $key_pointer = shift @flds;
    my $blocks_used = shift @flds;
    my $eof = shift @flds;
    my ($e1, $e2, $e3)  = unpack "C*", $eof;
    my $endfile = (($e3 << 16) + ($e2 << 8) + $e1);
    my $creation_ymd = shift @flds;
    my $creation_hm = shift @flds;
    my $cdate = date_convert($creation_ymd, $creation_hm);
    my $version = shift @flds;
    my $min_version = shift @flds;
    my $access = shift @flds;
    my $aux_type = shift @flds;
    my $atype = '';
    if ($file_type == 0x06) {
      $atype = sprintf("A=\$%04X", $aux_type);
    }
    my $last_mod_ymd = shift @flds;
    my $last_mod_hm = shift @flds;
    my $mdate = date_convert($last_mod_ymd, $last_mod_hm);
    my $header_pointer = shift @flds;
    if ($storage_type != 0x00) {
      my $f_type = $ftype{$file_type};
      $f_type = sprintf("\$%02x", $file_type) unless defined $f_type;
      push @files, { 'prv' => $prv_vol_dir_blk, 'nxt' => $nxt_vol_dir_blk, 'filename' => $fname, 'ftype' => $f_type, 'used' => $blocks_used, 'mdate' => $mdate, 'cdate' => $cdate, 'atype' => $aux_type, 'atype' => $atype, 'access' => $access, 'eof' => $endfile, 'keyptr' => $key_pointer, 'storage_type' => $storage_type, 'header_pointer' => $header_pointer, 'i' => $i };
    } else {
      if ($mode == 2) {
        push @files, { 'storage_type' => 0, 'header_pointer' => $header_pointer, 'i' => $i };
      }
    }
  }

  #if ($mode == 2) {
  #  foreach my $file (@files) {
  #    next if $file->{'storage_type'} != 0;
  #    print "file=$file->{'header_pointer'} $file->{'i'}\n";
  #  }
  #}

  return $prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volname, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files;
}

#
# Get Key Volume Directory Block
#
sub get_key_vol_dir_blk {
  my ($pofile, $mode, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my $buf;

  if (read_blk($pofile, $key_vol_dir_blk, \$buf)) {
    dump_blk($buf) if $debug;
    return parse_key_vol_dir_blk($buf, $mode, $debug);
  }

  return 0;
}

# Parse Volume Directory Block
sub parse_vol_dir_blk {
  my ($buf, $mode, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $dir_ents) = unpack $vol_dir_blk_tmpl, $buf;

  my @flds = unpack $dir_file_desc_ent_tmpl, $dir_ents;

  my @files = ();
  for (my $i = 0; $i < 12; $i++) {
    my $storage_type_name_length = shift @flds;
    my $storage_type = ($storage_type_name_length & 0xf0) >> 4;
    my $name_length = $storage_type_name_length & 0x0f;
    my $file_name = shift @flds;
    my $fname = substr($file_name, 0, $name_length);
    my $file_type = shift @flds;
    my $key_pointer = shift @flds;
    my $blocks_used = shift @flds;
    my $eof = shift @flds;
    my ($e1, $e2, $e3)  = unpack "C*", $eof;
    my $endfile = (($e3 << 16) + ($e2 << 8) + $e1);
    my $creation_ymd = shift @flds;
    my $creation_hm = shift @flds;
    my $cdate = date_convert($creation_ymd, $creation_hm);
    my $version = shift @flds;
    my $min_version = shift @flds;
    my $access = shift @flds;
    my $aux_type = shift @flds;
    my $atype = '';
    if ($file_type == 0x06) {
      $atype = sprintf("A=\$%04X", $aux_type);
    }
    my $last_mod_ymd = shift @flds;
    my $last_mod_hm = shift @flds;
    my $mdate = date_convert($last_mod_ymd, $last_mod_hm);
    my $header_pointer = shift @flds;
    if ($storage_type != 0x00) {
      my $f_type = $ftype{$file_type};
      $f_type = sprintf("\$%02x", $file_type) unless defined $f_type;
      push @files, { 'prv' => $prv_vol_dir_blk, 'nxt' => $nxt_vol_dir_blk, 'filename' => $fname, 'ftype' => $f_type, 'used' => $blocks_used, 'mdate' => $mdate, 'cdate' => $cdate, 'atype' => $aux_type, 'atype' => $atype, 'access' => $access, 'eof' => $endfile, 'keyptr' => $key_pointer, 'storage_type' => $storage_type, 'header_pointer' => $header_pointer, 'i' => $i };
    } else {
      if ($mode == 2) {
        push @files, { 'header_pointer' => $header_pointer, 'i' => $i };
      }
    }
  }

  return $prv_vol_dir_blk, $nxt_vol_dir_blk, @files;
}

#
# Get Volume Directory Block
#
sub get_vol_dir_blk {
  my ($pofile, $vol_dir_blk, $mode, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my $buf;

  if (read_blk($pofile, $vol_dir_blk, \$buf)) {
    dump_blk($buf) if $debug;
    return parse_vol_dir_blk($buf, $mode, $debug);
  }

  return 0;
}

# Parse Key Volume Directory Block
sub parse_subdir_hdr_blk {
  my ($buf, $mode, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $foo, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, $dir_ents) = unpack $subdir_hdr_blk_tmpl, $buf;

  my $storage_type = ($storage_type_name_length & 0xf0) >> 4;
  my $name_length = $storage_type_name_length & 0x0f;

  my $subdir_nm = substr($subdir_name, 0, $name_length);

  my @flds = unpack $subdir_hdr_file_desc_ent_tmpl, $dir_ents;

  my @files = ();
  for (my $i = 0; $i < 12; $i++) {
    my $storage_type_name_length = shift @flds;
    my $storage_type = ($storage_type_name_length & 0xf0) >> 4;
    printf("storage_type_name_length=%02x\n", $storage_type_name_length) if $debug;
    printf("storage_type=%02x\n", $storage_type) if $debug;
    my $name_length = $storage_type_name_length & 0x0f;
    printf("name_length=%02x\n", $name_length) if $debug;
    my $file_name = shift @flds;
    my $fname = substr($file_name, 0, $name_length);
    printf("fname=%s\n", $fname) if $debug;
    my $file_type = shift @flds;
    printf("file_type=%02x\n", $file_type) if $debug;
    my $key_pointer = shift @flds;
    my $blocks_used = shift @flds;
    my $eof = shift @flds;
    my ($e1, $e2, $e3)  = unpack "C*", $eof;
    my $endfile = (($e3 << 16) + ($e2 << 8) + $e1);
    my $creation_ymd = shift @flds;
    my $creation_hm = shift @flds;
    my $cdate = date_convert($creation_ymd, $creation_hm);
    my $version = shift @flds;
    my $min_version = shift @flds;
    my $access = shift @flds;
    my $aux_type = shift @flds;
    my $atype = '';
    if ($file_type == 0x06) {
      $atype = sprintf("A=\$%04X", $aux_type);
    }
    my $last_mod_ymd = shift @flds;
    my $last_mod_hm = shift @flds;
    my $mdate = date_convert($last_mod_ymd, $last_mod_hm);
    my $header_pointer = shift @flds;
    if ($storage_type != 0x00) {
      my $f_type = $ftype{$file_type};
      $f_type = sprintf("\$%02x", $file_type) unless defined $f_type;
      push @files, { 'prv' => $prv_vol_dir_blk, 'nxt' => $nxt_vol_dir_blk, 'filename' => $fname, 'ftype' => $f_type, 'used' => $blocks_used, 'mdate' => $mdate, 'cdate' => $cdate, 'atype' => $aux_type, 'atype' => $atype, 'access' => $access, 'eof' => $endfile, 'keyptr' => $key_pointer, 'storage_type' => $storage_type, 'header_pointer' => $header_pointer, 'i' => $i };
    } else {
      if ($mode == 2) {
        push @files, { 'header_pointer' => $header_pointer, 'i' => $i };
      }
    }
  }

  return $prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_nm, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @files;
}

sub get_subdir_hdr {
  my ($pofile, $subdir_blk, $mode, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my $buf;

  if (read_blk($pofile, $subdir_blk, \$buf)) {
    dump_blk($buf) if $debug;
    return parse_subdir_hdr_blk($buf, $mode, $debug);
  }

  print "I/O Error reading block $subdir_blk\n";

  return 0;
}

sub list_files {
  my ($pofile, $pre, $dirname, $files) = @_;

  print "$pre/$dirname\n";

  foreach my $file (@{$files}) {
    my $lck = ' ';
    if ($file->{'access'} == 0x01) {
      $lck = '*';
    }
    printf("$pre%s%-15s %3s %7d %16s %16s  %7s %s\n", $lck, $file->{'filename'}, $file->{'ftype'}, $file->{'used'}, $file->{'mdate'}, $file->{'cdate'}, $file->{'eof'}, $file->{'atype'});

    if ($file->{'ftype'} eq 'DIR') {
      my $subdir_blk = $file->{'keyptr'};

      my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @subfiles) = get_subdir_hdr($pofile, $subdir_blk, 1, $debug);

      list_files($pofile, '  ' . $pre, $subdir_name, \@subfiles);
    }
  }
}

#
# Get disk catalog.
#
sub cat {
  my ($pofile, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volume_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files) = get_key_vol_dir_blk($pofile, 1, $debug);

  print "/$volume_name\n\n";

  print " NAME           TYPE  BLOCKS  MODIFIED         CREATED          ENDFILE SUBTYPE\n\n";

  foreach my $file (@files) {
    my $lck = ' ';
    if ($file->{'access'} == 0x01) {
      $lck = '*';
    }
    printf("%s%-15s %3s %7d %16s %16s  %7s %s\n", $lck, $file->{'filename'}, $file->{'ftype'}, $file->{'used'}, $file->{'mdate'}, $file->{'cdate'}, $file->{'eof'}, $file->{'atype'});

    if ($file->{'ftype'} eq 'DIR') {
      my $subdir_blk = $file->{'keyptr'};

      my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @subfiles) = get_subdir_hdr($pofile, $subdir_blk, 1, $debug);
      my $pre = '  ';
      list_files($pofile, '  ' . $pre, $subdir_name, \@subfiles);
    }
  }

  my $vol_dir_blk = $nxt_vol_dir_blk;

  while ($vol_dir_blk) {
    my ($prv_vol_dir_blk, $nxt_vol_dir_blk, @files) = get_vol_dir_blk($pofile, $vol_dir_blk, 1, $debug);
    foreach my $file (@files) {
      my $lck = ' ';
      if ($file->{'access'} == 0x01) {
        $lck = '*';
      }
      printf("%s%-15s %3s %7d %16s %16s  %7s %s\n", $lck, $file->{'filename'}, $file->{'ftype'}, $file->{'used'}, $file->{'mdate'}, $file->{'cdate'}, $file->{'eof'}, $file->{'atype'});

      if ($file->{'ftype'} eq 'DIR') {
        my $subdir_blk = $file->{'keyptr'};

        my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @subfiles) = get_subdir_hdr($pofile, $subdir_blk, 1, $debug);

        my $pre = '  ';
        list_files($pofile, '  ' . $pre, $subdir_name, \@subfiles);
      }
    }
    $vol_dir_blk = $nxt_vol_dir_blk;
  }
}

# Parse master index block (tree file)
sub parse_master_ind_blk {
  my ($buf, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my @lo = unpack $master_ind_blk_lo_tmpl, $buf;
  my @hi = unpack $master_ind_blk_hi_tmpl, $buf;

  #print "lo=\n";
  #my $l = 0;
  #foreach my $lob (@lo) {
  #  print "\n" if !($l++ % 16);
  #  printf("%02x ", $lob);
  #}
  #print "\n";

  #print "hi=\n";
  #my $h = 0;
  #foreach my $hib (@hi) {
  #  print "\n" if !($h++ % 16);
  #  printf("%02x ", $hib);
  #}
  #print "\n";

  my @blocks = ();

  #print "blks=\n";
  foreach (my $blkno = 0; $blkno < 256; $blkno++) {
    #my $v = ($hi[$blkno] << 8) | $lo[$blkno];
    #printf("blkno=%d lo=%02x hi=%02x block=%04x\n", $blkno, $lo[$blkno], $hi[$blkno], $v);
    #print "\n" if !($blkno++ % 16);
    $blocks[$blkno] = ($hi[$blkno] << 8) | $lo[$blkno];
    #printf("%04x ", $blocks[$blkno]);
  }
  #print "\n";

  return @blocks;
}

# Get master index block (tree file)
sub get_master_ind_blk {
  my ($pofile, $master_ind_blk, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  #print "pofile=$pofile master_ind_blk=$master_ind_blk\n";

  my $buf;

  if (read_blk($pofile, $master_ind_blk, \$buf)) {
    dump_blk($buf) if $debug;
  } else {
    print "I/O Error reading block $master_ind_blk\n";
  }

  return parse_master_ind_blk($buf, $debug);
}

# Parse sub index block (tree file)
sub parse_sub_ind_blk {
  my ($buf, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my @lo = unpack $sub_ind_blk_lo_tmpl, $buf;
  my @hi = unpack $sub_ind_blk_hi_tmpl, $buf;

  #print "lo=\n";
  #my $l = 0;
  #foreach my $lob (@lo) {
  #  print "\n" if !($l++ % 16);
  #  printf("%02x ", $lob);
  #}
  #print "\n";

  #print "hi=\n";
  #my $h = 0;
  #foreach my $hib (@hi) {
  #  print "\n" if !($h++ % 16);
  #  printf("%02x ", $hib);
  #}
  #print "\n";

  my @blocks = ();

  #print "subblks=\n";
  foreach (my $blkno = 0; $blkno < 256; $blkno++) {
  #  print "\n" if !($blkno++ % 16);
    $blocks[$blkno] = ($hi[$blkno] << 8) | $lo[$blkno];
  #  printf("%04x ", $blocks[$blkno]);
  }
  #print "\n";

  return @blocks;
}

# Get sub index block (tree file)
sub get_sub_ind_blk {
  my ($pofile, $sub_ind_blk, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  #print "pofile=$pofile sub_ind_blk=$sub_ind_blk\n";

  my $buf;

  my @blocks = ();

  if (read_blk($pofile, $sub_ind_blk, \$buf)) {
    dump_blk($buf) if $debug;
    #dump_blk($buf);
  } else {
    print "I/O Error reading block $sub_ind_blk\n";
  }

  return parse_sub_ind_blk($buf, $debug);
}

# Get index block (sapling file)
sub get_ind_blk {
  my ($pofile, $ind_blk, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  #print "pofile=$pofile ind_blk=$ind_blk\n";

  my $buf;

  my @blocks = ();

  if (read_blk($pofile, $ind_blk, \$buf)) {
    dump_blk($buf) if $debug;
    my @lo = unpack "C256", $buf;
    #foreach my $byte (@lo) {
    #  printf("%02x ", $byte);
    #}
    #print "\n";
    my @hi = unpack "x256C256", $buf;
    #foreach my $byte (@hi) {
    #  printf("%02x ", $byte);
    #}
    #print "\n";
    for (my $b = 0; $b < 256; $b++) {
      #printf("lo=%02x hi=%02x\n", $lo[$b], $hi[$b]);
      my $blk = ($hi[$b] << 8) | $lo[$b];
      #printf("blk=%04x\n", $blk);
      push @blocks, $blk;
    }
    #print "blocks=\n";
    #my $x = 0;
    #foreach my $block (@blocks) {
    #  printf("%04x ", $block);
    #  $x++;
    #  print "\n" if !($x % 16);
    #}
    #print "\n";
  } else {
    print "I/O Error reading block $ind_blk\n";
  }

  return @blocks;
}

#
# Find empty file descriptive entry slot.
#
sub find_empty_fdescent {
  my ($pofile, $subdir, $dbg) = @_;

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volume_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files) = get_key_vol_dir_blk($pofile, 2, $debug);

  if (! defined $subdir || $subdir eq '') {
    # Must find a slot in the master directory.
    print "Master directory\n";
    my $found_it = 0;
    foreach my $file (@files) {
      next if ! defined $file->{'header_pointer'} || $file->{'header_pointer'} eq '';
      next if ($file->{'storage_type'} != 0);
      $found_it = 1;
print "Found empty slot $file->{'i'}\n";
      return $file->{'header_pointer'}, $file->{'i'};
    }

    print "No space in master directory\n";
##FIXME
  } else {
    # If subdir not found then bag out.
    print "Subdirectory $subdir\n";
##FIXME
  }

  print "No directory space available\n";

  return 0, 0;
}

#
# Find a file
#
sub find_file {
  my ($pofile, $filename, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  #print "pofile=$pofile filename=$filename\n";

  my $storage_type = 0;
  my $file_type = 0x00;
  my $key_pointer = 0x00;
  my $blocks_used = 0x00;
  my $eof = 0x00;
  my $header_pointer = '';
  my $file_index = 0;

  # Parse subdirectories
##FIXME -- needs to handle multiple subdirectory levels.
  my $base_dir = '';
  my $fname = '';
  if ($filename =~ /^(\S+)\/(\S+)/) {
    # Contains subdirs.
    $base_dir = $1;
    $fname = $2;
  }

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volume_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files) = get_key_vol_dir_blk($pofile, 1, $debug);

  my $found_it = 0;
  foreach my $file (@files) {
    if ($base_dir eq '') {
      #print "file=$file->{'filename'}\n";
      if ($file->{'filename'} eq $filename) {
        #print "FOUND IT!\n";
        $found_it = 1;
        $storage_type = $file->{'storage_type'};
        $file_type = $file->{'ftype'};
        $key_pointer = $file->{'keyptr'};
        $blocks_used = $file->{'used'};
        $eof = $file->{'eof'};
        $header_pointer = $file->{'header_pointer'};
        $file_index = $file->{'i'};
        last;
      }
    } else {
      if ($file->{'filename'} eq $base_dir) {
        #print "FOUND IT!\n";
        $found_it = 1;
        $storage_type = $file->{'storage_type'};
        $file_type = $file->{'ftype'};
        $key_pointer = $file->{'keyptr'};
        $blocks_used = $file->{'used'};
        $eof = $file->{'eof'};
        $header_pointer = $file->{'header_pointer'};
        $file_index = $file->{'i'};

        # Now read the subdir(s) and look for the file.
        my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @subfiles) = get_subdir_hdr($pofile, $key_pointer, 1, $debug);

        foreach my $subfile (@subfiles) {
          #print "filename=$subfile->{'filename'}\n";
          if ($subfile->{'filename'} eq $fname) {
            #print "FOUND IT!\n";
            $found_it = 1;
            $storage_type = $subfile->{'storage_type'};
            $file_type = $subfile->{'ftype'};
            $key_pointer = $subfile->{'keyptr'};
            $blocks_used = $subfile->{'used'};
            $eof = $subfile->{'eof'};
            $header_pointer = $subfile->{'header_pointer'};
            $file_index = $subfile->{'i'};
          }
        }
        last;
      }
    }
  }

  if (! $found_it) {
    my $vol_dir_blk = $nxt_vol_dir_blk;

    while ($vol_dir_blk) {
      my ($prv_vol_dir_blk, $nxt_vol_dir_blk, @files) = get_vol_dir_blk($pofile, $vol_dir_blk, 1, $debug);

      foreach my $file (@files) {
        if ($base_dir eq '') {
          #print "file=$file->{'filename'}\n";
          if ($file->{'filename'} eq $filename) {
            #print "FOUND IT!\n";
            $found_it = 1;
            $storage_type = $file->{'storage_type'};
            $file_type = $file->{'ftype'};
            $key_pointer = $file->{'keyptr'};
            $blocks_used = $file->{'used'};
            $eof = $file->{'eof'};
            $header_pointer = $file->{'header_pointer'};
            $file_index = $file->{'i'};
            last;
          }
        } else {
          if ($file->{'filename'} eq $base_dir) {
            #print "FOUND IT!\n";
            $found_it = 1;
            $storage_type = $file->{'storage_type'};
            $file_type = $file->{'ftype'};
            $key_pointer = $file->{'keyptr'};
            $blocks_used = $file->{'used'};
            $eof = $file->{'eof'};
            $header_pointer = $file->{'header_pointer'};
            $file_index = $file->{'i'};

            # Now read the subdir(s) and look for the file.
            my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @subfiles) = get_subdir_hdr($pofile, $key_pointer, 1, $debug);

            foreach my $subfile (@subfiles) {
              #print "filename=$subfile->{'filename'}\n";
              if ($subfile->{'filename'} eq $fname) {
                #print "FOUND IT!\n";
                $found_it = 1;
                $storage_type = $subfile->{'storage_type'};
                $file_type = $subfile->{'ftype'};
                $key_pointer = $subfile->{'keyptr'};
                $blocks_used = $subfile->{'used'};
                $eof = $subfile->{'eof'};
                $header_pointer = $subfile->{'header_pointer'};
                $file_index = $subfile->{'i'};
              }
            }
            last;
          }
        }
      }
      $vol_dir_blk = $nxt_vol_dir_blk;
      last if $found_it;
    }
  }

  print "File not found\n" unless $found_it;

  return $storage_type, $file_type, $key_pointer, $blocks_used, $eof, $header_pointer, $file_index;
}

#
# Read a file
#
sub read_file {
  my ($pofile, $filename, $mode, $conv, $text_conv, $output_file, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  $output_file = '' unless defined $output_file;

$debug = 1;
  print "pofile=$pofile filename=$filename mode=$mode conv=$conv text_conv=$text_conv output_filename=$output_file\n" if $debug;
$debug = 0;

  my ($storage_type, $file_type, $key_pointer, $blocks_used, $eof) = find_file($pofile, $filename, $debug);

  #print "storage_type=$storage_type file_type=$file_type key_pointer=$key_pointer blocks_used=$blocks_used eof=$eof\n";

  return 0 if $storage_type == 0;

  my $buf;

  my $ofh;

  if ($output_file eq '') {
    $ofh = \*STDOUT;
  } else {
    if (!open($ofh, ">$output_file")) {
      return 0;
    }
  }

  print "storage_type=$storage_type file_type=$file_type key_pointer=$key_pointer blocks_used=$blocks_used\n" if $debug;

  # Seedling file, only 1 block
  if ($storage_type == 1) {
    my $buf2;

    if (read_blk($pofile, $key_pointer, \$buf2)) {
      dump_blk($buf) if $debug;
      my @bytes = unpack "C*", $buf2;
      foreach my $byte (@bytes) {
        # For text file translation.
        last if $byte == 0x00 && $mode eq 'T';
        # Translate \r to \n
        $byte = 0x0a if $byte == 0x8d && $conv;
        # Convert Apple II ASCII to standard ASCII (clear high bit)
        $byte &= 0x7f if $mode eq 'T' || $text_conv;
        #printf("%c", $byte & 0x7f);
        printf("%c", $byte);
      }
    } else {
      print "I/O Error reading block $key_pointer\n";
    }
  # Sapling file, 2-256 blocks
  } elsif ($storage_type == 2) {
    my @blks = get_ind_blk($pofile, $key_pointer, $debug);

    my $buf2;

    my $blkno = 1;
    foreach my $blk (@blks) {
      #print "blkno=$blkno blk=$blk\n";
      clear_buf(\$buf2);
      if (read_blk($pofile, $blk, \$buf2)) {
        dump_blk($buf2) if $debug;
        my @bytes = unpack "C*", $buf2;
        #my $x = 0;
        #print "bytes=\n";
        foreach my $byte (@bytes) {
          # For text file translation.
          last if $byte == 0x00 && $mode eq 'T';
          # Translate \r to \n
          $byte = 0x0a if $byte == 0x8d && $conv;
          # Convert Apple II ASCII to standard ASCII (clear high bit)
          $byte &= 0x7f if $mode eq 'T' || $text_conv;
          print $ofh sprintf("%c", $byte);
          #$x++;
          #printf("%02x ", $byte);
          #print "\n" if !($x % 16);
        }
        #print "\n";
        #print "Wrote $x bytes\n";
      } else {
        print "I/O Error reading block $blk\n";
      }
      last if $blkno++ == $blocks_used - 1;
    }
    # Truncate file to size.
    my $result = truncate $ofh, $eof;
  # Tree file, 257+ blocks
  } elsif ($storage_type == 3) {
    my $buf2;

    my @blks = get_master_ind_blk($pofile, $key_pointer, $debug);

    #foreach my $blk (@blks) {
    #  print "blk=$blk\n";
    #  last if $blk == 0;
    #}
    my $blkno = 1;
    foreach my $blk (@blks) {
      #print "blkno=$blkno blk=$blk\n";
      last if $blk == 0;
      my @subblks = get_sub_ind_blk($pofile, $blk, $debug);

      foreach my $sblk (@subblks) {
        #print "sblk=$sblk\n";
        last if $sblk == 0;
      }
#die "ACK!\n";

      foreach my $subblk (@subblks) {
        last if $subblk == 0;
        clear_buf(\$buf2);
        if (read_blk($pofile, $subblk, \$buf2)) {
          dump_blk($buf2) if $debug;
          my @bytes = unpack "C*", $buf2;
          #my $x = 0;
          #print "bytes=\n";
          foreach my $byte (@bytes) {
            # For text file translation.
            last if $byte == 0x00 && $mode eq 'T';
            # Translate \r to \n
            $byte = 0x0a if $byte == 0x8d && $conv;
            # Convert Apple II ASCII to standard ASCII (clear high bit)
            $byte &= 0x7f if $mode eq 'T' || $text_conv;
            print $ofh sprintf("%c", $byte);
            #$x++;
            #printf("%02x ", $byte);
            #print "\n" if !($x % 16);
          }
          #print "\n";
          #print "Wrote $x bytes\n";
        } else {
          print "I/O Error reading block $subblk\n";
        }
        last if $blkno++ == $blocks_used - 1;
      }
      # Truncate file to size.
      my $result = truncate $ofh, $eof;
    }
  } else {
    print "Not a regular file!\n";
  }

  return 1;
}

#
# Parse volume bit map
#
sub parse_vol_bit_map {
  my ($buf, $dbg) = @_;

  my @blocks = ();

  my (@bytes) = unpack $vol_bit_map_tmpl, $buf;

  foreach my $byte (@bytes) {
    #printf("%02x ", $byte);
    #printf("%08b ", $byte);
    push @blocks, $byte;
  }
  print "\n";

  return @blocks;
}

#
# Pack volume bit map
#
sub pack_vol_bit_map {
  my ($bytes, $dbg) = @_;

  my $buf = pack $vol_bit_map_tmpl, @{$bytes};

  return $buf;
}

#
# Get volume bit map
#
sub get_vol_bit_map {
  my ($pofile, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volname, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files) = get_key_vol_dir_blk($pofile, 1, $debug);

  my $buf;

  #printf("bit_map_pointer=%04x\n", $bit_map_pointer) if $debug;

  # Need to use total_blocks to calculate the number of volume bit map blocks.
  #printf("total_blocks=\$%04x\n", $total_blocks);
  my $num_tracks = $total_blocks / 8;
  #printf("num_tracks=%d\n", $num_tracks);
  my $num_vol_bit_map_blks = ceil($num_tracks / 512.0);
  #printf("num_vol_bit_map_blks=%d\n", $num_vol_bit_map_blks);
  $num_vol_bit_map_blks = 1 if $num_vol_bit_map_blks < 1;
  #printf("num_vol_bit_map_blks=%d\n", $num_vol_bit_map_blks);

  my @blocks = ();

  my $trk = 0;
  for (my $blk = $bit_map_pointer; $blk < $bit_map_pointer + $num_vol_bit_map_blks; $blk++) {
    clear_buf(\$buf);
    if (read_blk($pofile, $bit_map_pointer, \$buf)) {
      dump_blk($buf) if $debug;
      my (@blks) = parse_vol_bit_map($buf, $debug);
      foreach my $blk (@blks) {
        #print "trk=$trk blk=$blk\n";
        last if $trk++ >= $num_tracks;
        #printf("%02x ", $blk);
        push @blocks, $blk;
      }
      #print "\n";
    } else {
      print "I/O Error reading block $bit_map_pointer\n";
    }
  }

  return @blocks;
}

sub write_vol_bit_map {
  my ($pofile, $bitmaps, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  #print "in write_vol_bit map\n";

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volname, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files) = get_key_vol_dir_blk($pofile, 1, $debug);

  printf("bit_map_pointer=%04x\n", $bit_map_pointer) if $debug;

  # Need to use total_blocks to calculate the number of volume bit map blocks.
  #printf("total_blocks=\$%04x\n", $total_blocks);
  my $num_tracks = $total_blocks / 8;
  #printf("num_tracks=%d\n", $num_tracks);
  my $num_vol_bit_map_blks = ceil($num_tracks / 512.0);
  #printf("num_vol_bit_map_blks=%d\n", $num_vol_bit_map_blks);
  $num_vol_bit_map_blks = 1 if $num_vol_bit_map_blks < 1;
  #printf("num_vol_bit_map_blks=%d\n", $num_vol_bit_map_blks);

  # Handle multiple vol bit map blocks
  for (my $vbmb = 0; $vbmb < $num_vol_bit_map_blks; $vbmb++) {
    my @bytes = splice @{$bitmaps}, 0, 512;

    my $buf = pack $vol_bit_map_tmpl, @bytes;

    if (!write_blk($pofile, $bit_map_pointer + $vbmb, \$buf)) {
      print "I/O Error writing block " . ($bit_map_pointer + $vbmb) . "\n";
      return 0;
    }
  }

  return 1;
}

#
# Count free blocks
#
sub freespace {
  my ($pofile, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my (@blocks) = get_vol_bit_map($pofile, $debug);

  my $free_blocks = 0;
  foreach my $byte (@blocks) {
    $free_blocks += $ones_count{($byte >> 4) & 0x0f};  # Blocks 7654
    $free_blocks += $ones_count{$byte & 0x0f};  # Blocks 3210
  }

  return $free_blocks;
}

#
# Display blocks free map
#
sub freemap {
  my ($pofile, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my (@blocks) = get_vol_bit_map($pofile, $debug);

  print "    01234567\n";
  print "   +--------\n";

  my $free_blocks = 0;
  my $max_trk = scalar @blocks;
  #print "max_trk=$max_trk\n";
  my $trk = 0;
  foreach my $byte (@blocks) {
    my $bits = sprintf("%08b", $byte);
    $bits =~ s/[0]/\*/g;
    $bits =~ s/[1]/ /g;
    printf("%2d |%s\n", $trk++, $bits);
    $free_blocks += $ones_count{($byte >> 4) & 0x0f};  # Blocks 7654
    $free_blocks += $ones_count{$byte & 0x0f};  # Blocks 3210
  }
  print "\nFree Blocks $free_blocks\n";
}

#
# Get list of free blocks
#
sub get_free_blocks {
  my ($pofile, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my (@blocks) = get_vol_bit_map($pofile, $debug);

  my @free_blocks = ();

  my $block = 0;
  foreach my $byte (@blocks) {
    for (my $bit = 0; $bit < 8; $bit++) {
      if ($byte & (1 << $bit)) {
        push @free_blocks, $block;
      }
      $block++;
    }
  }

  #print "Free blocks=\n";
  #my $blkno = 0;
  #foreach my $blk (@free_blocks) {
  #  print "\n" if !($blkno % 16);
  #  printf("%04x ", $blk);
  #  $blkno++;
  #}
  #print "\n";

  return @free_blocks;
}

#
# Write a file
#
sub write_file {
  my ($pofile, $filename, $mode, $conv, $apple_filename, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  print "pofile=$pofile filename=$filename mode=$mode conv=$conv apple_filename=$apple_filename\n" if $debug;

  return 0 if ! -e $filename;

  # Get size of input file
  my $fsize = -s $filename;
  print "fsize=$fsize\n";

  my $numblocks = int($fsize / 512) + (($fsize % 512) ? 1 : 0);
  print "numblocks=$numblocks\n";

  my $blocks_used = $numblocks;

  # Get list of free blocks.
  my @free_blocks = get_free_blocks($pofile, $debug);

  my $free_count = scalar @free_blocks;

  if ($free_count < $numblocks) {
    print "Not enough space on volume, $free_count free blocks, need $numblocks\n";
    return 0;
  }

  my $subdir = '';
  my $apple_fname = $apple_filename;
  if ($apple_filename =~ /^[\/]*([^\/]+)\/(\S+)$/) {
    $subdir = $1;
    $apple_fname = $2;
  }
  print "subdir=$subdir apple_fname=$apple_fname\n";

  # Find an empty file descriptive entry in the proper subdirectory.
  my ($header_pointer, $i) = find_empty_fdescent($pofile, $subdir, $debug);
  printf("header_pointer=\$%04x i=%d\n", $header_pointer, $i);
##FIXME
  # May need to add a subdirectory block if the directory is full.
##FIXME

  my $rv = 1;

  my $file_storage_type = 0x00;
  my $file_type = 0x00;
##FIXME
  my $key_pointer = 0x00;
  my $aux_type = 0x00;
##FIXME

  # Read in the file.
  my $ifh;
  my $file_buffer;
  my @used_blocks = ();
  if (open($ifh, "<$filename")) {
    my $file_buffer = <$ifh>;

    my @bytes = unpack "C*", $file_buffer;

    if ($numblocks == 1) {
      # Seedling file.
      $file_storage_type = 0x10;

      # Get a block off the free blocks list.
      my $blknum = pop @free_blocks;
      $key_pointer = $blknum;

      print "blknum=$blknum\n";

      # Pack the data for the block.
      my $blkbuf = pack "C*", @bytes;

      # Write the single block
      if (!write_blk($pofile, $blknum, \$blkbuf)) {
        print "I/O Error writeing block $blknum\n";
        return 0;
      } else {
        # Add the block to the used blocks.
        push @used_blocks, $blknum;
      }
    } elsif ($numblocks <= 256) {
      # Sapling file.
      $file_storage_type = 0x20;

      # Get a block off the free blocks list for the index block.
      my $blknum = pop @free_blocks;
      $key_pointer = $blknum;

      # Data for index block.
      my @indbytes = ();

      # Add index block to used blocks
      push @used_blocks, $blknum;

      # Write out the data blocks.
      for (my $blk = 0; $blk < $numblocks; $blk++) {
        # Get a free block.
        my $datablknum = pop @free_blocks;

        # Get the data for this block
        my @databytes = splice @bytes, 0, 512;

        # Pack the data.
        my $databuf = pack "C*", @databytes;

        # Write out the block
        if (!write_blk($pofile, $datablknum, \$databuf)) {
          print "I/O Error writeing block $datablknum\n";
        }

        # Add each block to used blocks list.
        push @used_blocks, $datablknum;

        # Add block to index block
        $indbytes[$blk] = $datablknum & 0xff00;  # LO byte
        $indbytes[$blk + 256] = $datablknum >> 8;  # HI byte
      }

      my $indbuf = pack "C*", @indbytes;

      # Write out the index block.
      if (!write_blk($pofile, $blknum, \$indbuf)) {
        print "I/O Error writing block $blknum\n";
        return 0;
      }
    } else {
      # Tree file.
      $file_storage_type = 0x30;

      # Create the master index block.
      my @master_index = ();
      my $masterblknum = pop @free_blocks;
      $key_pointer = $masterblknum;

      # Add master index block to used blocks
      push @used_blocks, $masterblknum;

      # Create the first subindex block.
      my @indbytes = ();
      my $subblknum = pop @free_blocks;

      # Write out the data blocks.
      my $cursub = 0;
      my $curblk = 0;
      for (my $blk = 0; $blk < $numblocks; $blk++) {
        # Get a free block.
        my $datablknum = pop @free_blocks;

        # Get the data for this block
        my @databytes = splice @bytes, 0, 512;

        # Add each block to used blocks list.
        push @used_blocks, $datablknum;
        my $subblknum = pop @free_blocks;

        # Add block to current sub index block
        $indbytes[$curblk] = $datablknum & 0xff00;  # LO byte
        $indbytes[$curblk + 256] = $datablknum >> 8;  # HI byte
        $curblk++;

        # If the current index block is full or last block write out the sub index block.
        if ($curblk > 255 || $blk == ($numblocks - 1)) {
          # Add each subindex block to used blocks
          push @used_blocks, $subblknum;

          # Write out the sub index block
          my $subindexbuf = pack "C*", @indbytes;

          if (!write_blk($pofile, $subblknum, \$subindexbuf)) {
            print "I/O Error writing block $subblknum\n";
            return 0;
          }

          # Add each sub index block to the master block.
          $master_index[$cursub] = $subblknum & 0xff00;  # LO byte
          $master_index[$cursub + 1] = $subblknum >> 8;  # HI byte
          $cursub += 2;

          # Get ready for next index block.
          $curblk = 0;
          @indbytes = ();
          $subblknum = pop @free_blocks;
        }
      }

      # Write out the master index block.
      my $masterbuf = pack "C*", @master_index;

      if (!write_blk($pofile, $masterblknum, \$masterbuf)) {
        print "I/O Error writing block $masterblknum\n";
        return 0;
      }
    }

    # Read & rewrite the file descriptive entry out.
    my $dirbuf;

    $header_pointer = 2 if $header_pointer == 0;

    if (read_blk($pofile, $header_pointer, \$dirbuf)) {
      dump_blk($dirbuf) if $debug;
      dump_blk($dirbuf);

      my @bytes = unpack "C*", $dirbuf;

      my $storage_type = $bytes[4] >> 4;
      #printf("storage_type=\$%02x\n", $storage_type);

      if ($storage_type == 0x0f || $storage_type == 0x0e) {
        # Fill in STORAGE_TYPE/NAME_LENGTH
        #printf("file_storage_type=\$%02x\n", $file_storage_type);
        $file_storage_type &= 0xf0;
        #printf("file_storage_type=\$%02x\n", $file_storage_type);
        $file_storage_type |= length($apple_filename);
        $bytes[0x2b + ($i* 0x27)] = $file_storage_type;
        #printf("file_storage_type=\$%02x\n", $file_storage_type);

        # Fill in FILE_NAME
        my $filename_start = 0x2b + ($i * 0x27) + 0x01;
        #print"filename_start=$filename_start\n";
        #print "filename='";
        my $j = 0;
        for (my $i = $filename_start; $i < ($filename_start + 15); $i++) {
          #printf("%c", $bytes[$i]);
          if ($j < length($apple_filename)) {
            $bytes[$i] = ord(substr($apple_filename, $j++, 1));
          } else {
            $bytes[$i] = 0x00;
          }
        }
        #print "'\n";
        #print "filename='";
        #for (my $i = $filename_start; $i < ($filename_start + 15); $i++) {
        #  printf("%c", $bytes[$i]);
        #}
        #print "'\n";

        # Fill in FILE_TYPE
        $bytes[0x2b + ($i * 0x27) + 0x10] = $file_type;

        # Fill in LO byte of KEY_POINTER
        $bytes[0x2b + ($i * 0x27) + 0x11] = $key_pointer & 0x00ff;
        # Fill in HI byte of KEY_POINTER
        $bytes[0x2b + ($i * 0x27) + 0x12] = (($key_pointer & 0xff00) >> 8);

        # Fill in LO byte of BLOCKS_USED
        $bytes[0x2b + ($i * 0x27) + 0x13] = $blocks_used & 0x00ff;
        # Fill in HI byte of BLOCKS_USED
        $bytes[0x2b + ($i * 0x27) + 0x14] = (($blocks_used & 0xff00) >> 8);

        # Fill in EOF
        $bytes[0x2b + ($i * 0x27) + 0x15] = $fsize & 0x0000ff;
        $bytes[0x2b + ($i * 0x27) + 0x16] = ($fsize & 0x00ff00) >> 8;
        $bytes[0x2b + ($i * 0x27) + 0x17] = ($fsize & 0xff0000) >> 16;

        # Fill in CREATION
        $bytes[0x2b + ($i * 0x27) + 0x18] = 0x00;
        $bytes[0x2b + ($i * 0x27) + 0x19] = 0x00;
        $bytes[0x2b + ($i * 0x27) + 0x1a] = 0x00;
        $bytes[0x2b + ($i * 0x27) + 0x1b] = 0x00;
##FIXME

        # Fill in VERSION -- default to ProDOS 1.0
        $bytes[0x2b + ($i * 0x27) + 0x1c] = 0x00;

        # Fill in MIN_VERSION -- default to ProDOS 1.0
        $bytes[0x2b + ($i * 0x27) + 0x1d] = 0x00;

        # Fill in ACCESS -- default to unlocked.
        $bytes[0x2b + ($i * 0x27) + 0x1e] = 0xc3;

        # Fill in LO byte of AUX_TYPE
        $bytes[0x2b + ($i * 0x27) + 0x1f] = $aux_type & 0x00ff;
        # Fill in HI byte of AUX_TYPR
        $bytes[0x2b + ($i * 0x27) + 0x20] = (($aux_type & 0xff00) >> 8);
##FIXME

        # Fill in LAST_MOD
        $bytes[0x2b + ($i * 0x27) + 0x21] = 0x00;
        $bytes[0x2b + ($i * 0x27) + 0x22] = 0x00;
        $bytes[0x2b + ($i * 0x27) + 0x23] = 0x00;
        $bytes[0x2b + ($i * 0x27) + 0x24] = 0x00;
##FIXME

        # Fill in LO byte of HEADER_POINTER
        $bytes[0x2b + ($i * 0x27) + 0x25] = $header_pointer & 0x00ff;
        # Fill in HI byte of HEADER_POINTER
        $bytes[0x2b + ($i * 0x27) + 0x26] = (($header_pointer & 0xff00) >> 8);
      } else {
        printf("Invalid storage type \$%02x\n", $storage_type);
        return 0;
      }

      $dirbuf = pack "C*", @bytes;

      dump_blk($dirbuf) if $debug;
      dump_blk($dirbuf);

      # Write the file descriptive entry back out.
      if (!write_blk($pofile, $header_pointer, \$dirbuf)) {
        print "I/O Error writing block $header_pointer\n";
##FIXME
        return 0;
      }
    } else {
      print "I/O Error reading block $header_pointer\n";
##FIXME
      return 0;
    }

    # Mark blocks as used.
    $rv = reserve_blocks($pofile, \@used_blocks, $debug);
  } else {
    return 0;
  }

  return 1;
}

#
# Rename a file
#
sub rename_file {
  my ($pofile, $filename, $new_filename, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  #print "pofile=$pofile filename=$filename new_filename=$new_filename\n" if $debug;

  my ($storage_type, $file_type, $key_pointer, $blocks_used, $eof, $header_pointer, $i) = find_file($pofile, $filename, $debug);

  #print "storage_type=$storage_type file_type=$file_type key_pointer=$key_pointer blocks_used=$blocks_used eof=$eof header_pointer=$header_pointer i=$i\n";

  return 0 if $storage_type == 0;

  my $buf;

  if (read_blk($pofile, $header_pointer, \$buf)) {
    dump_blk($buf) if $debug;
    #dump_blk($buf);

    my @bytes = unpack "C*", $buf;

    my $storage_type = $bytes[4] >> 4;
    #printf("storage_type=\$%02x\n", $storage_type);

    if ($storage_type == 0x0f || $storage_type == 0x0e) {
      my $file_storage_type = $bytes[0x2b + ($i* 0x27)];
      #printf("file_storage_type=\$%02x\n", $file_storage_type);
      $file_storage_type &= 0xf0;
      #printf("file_storage_type=\$%02x\n", $file_storage_type);
      $file_storage_type |= length($new_filename);
      $bytes[0x2b + ($i* 0x27)] = $file_storage_type;
      #printf("file_storage_type=\$%02x\n", $file_storage_type);
      my $filename_start = 0x2b + ($i * 0x27) + 0x01;
      #print"filename_start=$filename_start\n";
      #print "filename='";
      my $j = 0;
      for (my $i = $filename_start; $i < ($filename_start + 15); $i++) {
        #printf("%c", $bytes[$i]);
        if ($j < length($new_filename)) {
          $bytes[$i] = ord(substr($new_filename, $j++, 1));
        } else {
          $bytes[$i] = 0x00;
        }
      }
      #print "'\n";
      #print "filename='";
      #for (my $i = $filename_start; $i < ($filename_start + 15); $i++) {
      #  printf("%c", $bytes[$i]);
      #}
      #print "'\n";
    } else {
      printf("Invalid storage type \$%02x\n", $storage_type);
      return 0;
    }

    $buf = pack "C*", @bytes;

    dump_blk($buf) if $debug;

    if (!write_blk($pofile, $header_pointer, \$buf)) {
      print "I/O Error writing block $header_pointer\n";
      return 0;
    }
  } else {
    print "I/O Error reading block $header_pointer\n";
    return 0;
  }

  return 1;
}

#
# Reserve a list of used blocks.
#
sub reserve_blocks {
  my ($pofile, $used_blocks, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  # Get the volume bit map (blocks used/free).
  my (@bitmaps) = get_vol_bit_map($pofile, $debug);

  # Mark blocks in list as used in the bit map.
  foreach my $cur_blk (@{$used_blocks}) {
    #printf("cur_blk=%d byte=%d bit=%d\n", $cur_blk, $cur_blk / 8, $cur_blk % 8);
    $bitmaps[$cur_blk / 8] &= ~(1 << ($cur_blk % 8));
    last if $cur_blk == 0;
  }

  # Now write the volume bit map back out.
  return write_vol_bit_map($pofile, \@bitmaps, $debug);
}

#
# Free a list of blocks.
#
sub release_blocks {
  my ($pofile, $free_blocks, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  # Get the volume bit map (blocks used/free).
  my (@bitmaps) = get_vol_bit_map($pofile, $debug);

  #foreach my $byte (@blocks) {
  #  printf("byte=\$%02x\n", $byte);
  #}

  # Free blocks in the bit map.
  foreach my $cur_blk (@{$free_blocks}) {
    #printf("cur_blk=%d byte=%d bit=%d\n", $cur_blk, $cur_blk / 8, $cur_blk % 8);
    $bitmaps[$cur_blk / 8] |= (1 << ($cur_blk % 8));
    last if $cur_blk == 0;
  }

  #foreach my $byte (@blocks) {
  #  printf("byte=\$%02x\n", $byte);
  #}

  # Now write the volume bit map back out.
  return write_vol_bit_map($pofile, \@bitmaps, $debug);
}

#
# Delete a file
#
sub delete_file {
  my ($pofile, $filename, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  print "pofile=$pofile filename=$filename\n" if $debug;

  my ($storage_type, $file_type, $key_pointer, $blocks_used, $eof, $header_pointer, $i) = find_file($pofile, $filename, $debug);

  #print "storage_type=$storage_type file_type=$file_type key_pointer=$key_pointer blocks_used=$blocks_used eof=$eof header_pointer=$header_pointer i=$i\n";

  return 0 if $storage_type == 0;

  my $buf;

  my $rv = 1;

  if (read_blk($pofile, $header_pointer, \$buf)) {
    dump_blk($buf) if $debug;

    my @bytes = unpack "C*", $buf;

    my $storage_type = $bytes[4] >> 4;
    #printf("storage_type=\$%02x\n", $storage_type);

    if ($storage_type == 0x0f || $storage_type == 0x0e) {
      my $file_storage_type = $bytes[0x2b + ($i * 0x27)];
      printf("file_storage_type=\$%02x\n", $file_storage_type);
      $file_storage_type &= 0xf0;
      printf("file_storage_type=\$%02x\n", $file_storage_type);
      # Set file storage type to 0x00, which means deleted.
      $bytes[0x2b + ($i * 0x27)] = 0x00;
      printf("file_storage_type=\$%02x\n", $file_storage_type);

      # Now free all the blocks
      if ($file_storage_type == 0x10) {
        # Seedling file.
        $rv = release_blocks($pofile, [ $key_pointer ], $debug );
      } elsif ($file_storage_type == 0x20) {
        # Sapling file.
        my @blks = get_ind_blk($pofile, $key_pointer, $debug);

        $rv = release_blocks($pofile, \@blks, $debug);
      } elsif ($file_storage_type == 0x30) {
        # Tree file.
        ##TESTME
        my $buf2;

        my @blks = get_master_ind_blk($pofile, $key_pointer, $debug);

        my @blocks = ();
        #foreach my $blk (@blks) {
        #  print "blk=$blk\n";
        #  last if $blk == 0;
        #}
        my $blkno = 1;
        foreach my $blk (@blks) {
          #print "blkno=$blkno blk=$blk\n";
          last if $blk == 0;
          my @subblks = get_sub_ind_blk($pofile, $blk, $debug);
          #print "Pushing $blk\n";
          push @blocks, $blk;

          #foreach my $sblk (@subblks) {
          #  print "sblk=$sblk\n";
          #  last if $sblk == 0;
          #}

          foreach my $subblk (@subblks) {
            last if $subblk == 0;
            #print "Pushing $subblk\n";
            push @blocks, $subblk;
            last if $blkno++ == $blocks_used - 1;
          }
        }
        $rv = release_blocks($pofile, \@blocks, $debug);
      } elsif ($file_storage_type == 0xd0 || $file_storage_type == 0xe0) {
        # Subdirectory.
        # Subdirectory Header.
        my @subdirblks = ();
        push @subdirblks, $key_pointer;
        my $subdirblk = $key_pointer;
        my $done = 0;
        while (!$done) {
          my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @subfiles) = get_subdir_hdr($pofile, $subdirblk, 1, $debug);
          if ($nxt_vol_dir_blk == 0x0000) {
            $done = 1;
          } else {
            push @subdirblks, $nxt_vol_dir_blk;
            $subdirblk = $nxt_vol_dir_blk;
          }
        }
        $rv = release_blocks($pofile, \@subdirblks, $debug);
      } elsif ($file_storage_type == 0xf0) {
        # Volume directory Header.  This should never happen.
        printf("Can't delete volume directory header \$%02x\n", $header_pointer);

        return 0;
      } else {
        # Don't know what the file type is.  This should never happen.
        printf("Unknown storage type \$%02x\n", $file_storage_type);

        return 0;
      }
    } else {
      printf("Invalid storage type \$%02x\n", $storage_type);
      return 0;
    }

    $buf = pack "C*", @bytes;

    dump_blk($buf) if $debug;

    # Write the file descriptive entry back back out.
    if (!write_blk($pofile, $header_pointer, \$buf)) {
      print "I/O Error writing block $header_pointer\n";
      return 0;
    }
  } else {
    print "I/O Error reading block $header_pointer\n";
    return 0;
  }

  print "File deleted\n";

  return $rv;
}

#
# Copy a file
#
sub copy_file {
  my ($pofile, $filename, $copy_filename, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  print "pofile=$pofile filename=$filename copy_filename=$copy_filename\n" if $debug;
}

#
# Lock a file
#
sub lock_file {
  my ($pofile, $filename, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  print "pofile=$pofile filename=$filename\n" if $debug;

  my ($storage_type, $file_type, $key_pointer, $blocks_used, $eof, $header_pointer, $i) = find_file($pofile, $filename, $debug);

  print "storage_type=$storage_type file_type=$file_type key_pointer=$key_pointer blocks_used=$blocks_used eof=$eof header_pointer=$header_pointer i=$i\n";

  return 0 if $storage_type == 0;

  my $buf;

  if (read_blk($pofile, $header_pointer, \$buf)) {
    dump_blk($buf) if $debug;
    dump_blk($buf);

    my @bytes = unpack "C*", $buf;

    my $storage_type = $bytes[4] >> 4;
    printf("storage_type=\$%02x\n", $storage_type);

    if ($storage_type == 0x0f || $storage_type == 0x0e) {
      my $access = $bytes[0x2b + ($i * 0x27) + 0x1e];
      #printf("access=\$%02x\n", $access);
      $access &= 0x21;
      #printf("access=\$%02x\n", $access);
      $bytes[0x2b + ($i * 0x27) + 0x1e] = $access;
    } else {
      printf("Invalid storage type \$%02x\n", $storage_type);
      return 0;
    }

    $buf = pack "C*", @bytes;

    if (!write_blk($pofile, $header_pointer, \$buf)) {
      print "I/O Error writing block $header_pointer\n";
      return 0;
    }
  } else {
    print "I/O Error reading block $header_pointer\n";
    return 0;
  }

  return 1;
}

#
# Unlock a file
#
sub unlock_file {
  my ($pofile, $filename, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  print "pofile=$pofile filename=$filename\n" if $debug;

  my ($storage_type, $file_type, $key_pointer, $blocks_used, $eof, $header_pointer, $i) = find_file($pofile, $filename, $debug);

  print "storage_type=$storage_type file_type=$file_type key_pointer=$key_pointer blocks_used=$blocks_used eof=$eof header_pointer=$header_pointer i=$i\n";

  return 0 if $storage_type == 0;

  my $buf;

  if (read_blk($pofile, $header_pointer, \$buf)) {
    dump_blk($buf) if $debug;
    dump_blk($buf);

    my @bytes = unpack "C*", $buf;

    my $storage_type = $bytes[4] >> 4;
    printf("storage_type=\$%02x\n", $storage_type);

    if ($storage_type == 0x0f || $storage_type == 0x0e) {
      my $access = $bytes[0x2b + ($i * 0x27) + 0x1e];
      #printf("access=\$%02x\n", $access);
      $access |= 0x80;
      $access |= 0x40;
      $access |= 0x02;
      $access |= 0x01;
      #printf("access=\$%02x\n", $access);
      $bytes[0x2b + ($i * 0x27) + 0x1e] = $access;
    } else {
      printf("Invalid storage type \$%02x\n", $storage_type);
      return 0;
    }

    $buf = pack "C*", @bytes;

    if (!write_blk($pofile, $header_pointer, \$buf)) {
      print "I/O Error writing block $header_pointer\n";
      return 0;
    }
  } else {
    print "I/O Error reading block $header_pointer\n";
    return 0;
  }

  return 1;
}

#
# Create a subdirectory.
#
sub create_subdir {
  my ($pofile, $subdirname, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  print "pofile=$pofile subdirname=$subdirname\n" if $debug;

  my $subdir = '';
  my $subdir_fname = $subdirname;
  if ($subdirname =~ /^[\/]*([^\/]+)\/(\S+)$/) {
    $subdir = $1;
    $subdir_fname = $2;
  }
  print "subdir=$subdir subdir_fname=$subdir_fname\n";

  # Find an empty file descriptive entry in the proper subdirectory.
  my ($header_pointer, $i) = find_empty_fdescent($pofile, $subdir, $debug);
  printf("header_pointer=\$%04x i=%d\n", $header_pointer, $i);
  # May need to add a subdirectory block if the directory is full.
##FIXME
  if ($header_pointer == 0) {
    print "No directory slots available.\n";
    return 0 
  }
##FIXME

  my $rv = 1;

  my $buf;

  # Read in the directory.
  if (read_blk($pofile, $header_pointer, \$buf)) {
    dump_blk($buf) if $debug;

    # Unpack the directory block.
    my @bytes = unpack "C*", $buf;

    # Fill in the file type in the file descriptive entry
    my $file_storage_type = 0xd0;
    $file_storage_type |= length($subdirname);
    my $file_type = 0x0f;
##FIXME

    # Fill in STORAGE_TYPE/NAME_LENGTH
    $bytes[0x2b + ($i * 0x27)] = $file_storage_type;
    # Fill in FILE_NAME
    my $filename_start = 0x2b + ($i * 0x27) + 0x01;
    #print"filename_start=$filename_start\n";
    #print "filename='";
    my $j = 0;
    for (my $i = $filename_start; $i < ($filename_start + 15); $i++) {
      #printf("%c", $bytes[$i]);
      if ($j < length($subdirname)) {
        $bytes[$i] = ord(substr($subdirname, $j++, 1));
      } else {
        $bytes[$i] = 0x00;
      }
    }
    #print "'\n";
    #print "filename='";
    #for (my $i = $filename_start; $i < ($filename_start + 15); $i++) {
    #  printf("%c", $bytes[$i]);
    #}
    #print "'\n";

    # Create the subdirectory block.
    my @subdirbytes = ();

    # Get list of free blocks.
    my @free_blocks = get_free_blocks($pofile, $debug);

    # Get block from free block list for this directory.
    my $subdirblknum = pop @free_blocks;
    my $subdir_key_pointer = $subdirblknum;

    # Fill in the subdirectory block.
##FIXME
    # Fill in STORAGE_TYPE/NAME_LENGTH
    $subdirbytes[0x04] = $file_storage_type;
    # Fill in SUBDIR_NAME
    $j = 0;
    for (my $i = 0x05; $i <= 0x13; $i++) {
      if ($j < length($subdirname)) {
        $subdirbytes[$i] = ord(substr($subdirname, $j++, 1));
      } else {
        $subdirbytes[$i] = 0x00;
      }
    }

    my $subdirbuf = pack "C*", @subdirbytes;

    # Write the new directory block out.
    if (!write_blk($pofile, $subdirblknum, \$subdirbuf)) {
      print "I/O Error writing block $subdirblknum\n";
      return 0;
    }

    # Mark the subdir block as used.
    my @used_blocks = ();
    push @used_blocks, $subdirblknum;
    $rv = reserve_blocks($pofile, \@used_blocks, $debug);

    # Write file descriptive entry back out.
##FIXME
    $buf = pack "C*", @bytes;

    if (!write_blk($pofile, $header_pointer, \$buf)) {
      print "I/O Error writing block $header_pointer\n";
      return 0;
    }
  } else {
    print "I/O Error reading block $header_pointer\n";
    return 0;
  }

  return $rv;
}

1;

