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

# ProDOS file types
my %ftype = (
  # $0x Types: General

  # 00        Typeless file
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
  my ($buf, $dbg) = @_;

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
    if ($storage_type != 0) {
      my $f_type = $ftype{$file_type};
      $f_type = sprintf("\$%02x", $file_type) unless defined $f_type;
      push @files, { 'filename' => $fname, 'ftype' => $f_type, 'used' => $blocks_used, 'mdate' => $mdate, 'cdate' => $cdate, 'atype' => $aux_type, 'atype' => $atype, 'access' => $access, 'eof' => $endfile, 'keyptr' => $key_pointer, 'storage_type' => $storage_type };
    }
  }

  return $prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volname, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files;
}

#
# Get Key Volume Directory Block
#
sub get_key_vol_dir_blk {
  my ($pofile, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my $buf;

  if (read_blk($pofile, $key_vol_dir_blk, \$buf)) {
    dump_blk($buf) if $debug;
    return parse_key_vol_dir_blk($buf, $debug);
  }

  return 0;
}

# Parse Volume Directory Block
sub parse_vol_dir_blk {
  my ($buf, $dbg) = @_;

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
    if ($storage_type != 0) {
      my $f_type = $ftype{$file_type};
      $f_type = sprintf("\$%02x", $file_type) unless defined $f_type;
      push @files, { 'filename' => $fname, 'ftype' => $f_type, 'used' => $blocks_used, 'mdate' => $mdate, 'cdate' => $cdate, 'atype' => $aux_type, 'atype' => $atype, 'access' => $access, 'eof' => $endfile, 'keyptr' => $key_pointer, 'storage_type' => $storage_type };
    }
  }

  return $prv_vol_dir_blk, $nxt_vol_dir_blk, @files;
}

#
# Get Volume Directory Block
#
sub get_vol_dir_blk {
  my ($pofile, $vol_dir_blk, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my $buf;

  if (read_blk($pofile, $vol_dir_blk, \$buf)) {
    dump_blk($buf) if $debug;
    return parse_vol_dir_blk($buf, $debug);
  }

  return 0;
}

# Parse Key Volume Directory Block
sub parse_subdir_hdr_blk {
  my ($buf, $dbg) = @_;

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
    print sprintf("storage_type_name_length=%02x\n", $storage_type_name_length);
    print sprintf("storage_type=%02x\n", $storage_type);
    my $name_length = $storage_type_name_length & 0x0f;
    print sprintf("name_length=%02x\n", $name_length) if $debug;
    my $file_name = shift @flds;
    my $fname = substr($file_name, 0, $name_length);
    print sprintf("fname=%s\n", $fname) if $debug;
    my $file_type = shift @flds;
    print sprintf("file_type=%02x\n", $file_type) if $debug;
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
    if ($storage_type != 0) {
      my $f_type = $ftype{$file_type};
      $f_type = sprintf("\$%02x", $file_type) unless defined $f_type;
      push @files, { 'filename' => $fname, 'ftype' => $f_type, 'used' => $blocks_used, 'mdate' => $mdate, 'cdate' => $cdate, 'atype' => $aux_type, 'atype' => $atype, 'access' => $access, 'eof' => $endfile, 'keyptr' => $key_pointer, 'storage_type' => $storage_type };
    }
  }

  return $prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_nm, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @files;
}

sub get_subdir_hdr {
  my ($pofile, $subdir_blk, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my $buf;

  if (read_blk($pofile, $subdir_blk, \$buf)) {
    dump_blk($buf) if $debug;
    return parse_subdir_hdr_blk($buf, $debug);
  }

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
    print sprintf("$pre%s%-15s %3s %7d %16s %16s  %7s %s\n", $lck, $file->{'filename'}, $file->{'ftype'}, $file->{'used'}, $file->{'mdate'}, $file->{'cdate'}, $file->{'eof'}, $file->{'atype'});

    if ($file->{'ftype'} eq 'DIR') {
      my $subdir_blk = $file->{'keyptr'};

      my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @subfiles) = get_subdir_hdr($pofile, $subdir_blk, $debug);

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

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volume_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files) = get_key_vol_dir_blk($pofile, $debug);

  print "/$volume_name\n\n";

  print " NAME           TYPE  BLOCKS  MODIFIED         CREATED          ENDFILE SUBTYPE\n\n";

  foreach my $file (@files) {
    my $lck = ' ';
    if ($file->{'access'} == 0x01) {
      $lck = '*';
    }
    print sprintf("%s%-15s %3s %7d %16s %16s  %7s %s\n", $lck, $file->{'filename'}, $file->{'ftype'}, $file->{'used'}, $file->{'mdate'}, $file->{'cdate'}, $file->{'eof'}, $file->{'atype'});

    if ($file->{'ftype'} eq 'DIR') {
      my $subdir_blk = $file->{'keyptr'};

      my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @subfiles) = get_subdir_hdr($pofile, $subdir_blk, $debug);
      my $pre = '  ';
      list_files($pofile, '  ' . $pre, $subdir_name, \@subfiles);
    }
  }

  my $vol_dir_blk = $nxt_vol_dir_blk;

  while ($vol_dir_blk) {
    my ($prv_vol_dir_blk, $nxt_vol_dir_blk, @files) = get_vol_dir_blk($pofile, $vol_dir_blk, $debug);
    foreach my $file (@files) {
      my $lck = ' ';
      if ($file->{'access'} == 0x01) {
        $lck = '*';
      }
      print sprintf("%s%-15s %3s %7d %16s %16s  %7s %s\n", $lck, $file->{'filename'}, $file->{'ftype'}, $file->{'used'}, $file->{'mdate'}, $file->{'cdate'}, $file->{'eof'}, $file->{'atype'});

      if ($file->{'ftype'} eq 'DIR') {
        my $subdir_blk = $file->{'keyptr'};

        my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $subdir_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $parent_pointer, $parent_entry, $parent_entry_length, @subfiles) = get_subdir_hdr($pofile, $subdir_blk, $debug);

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
}

# Get master index block (tree file)
sub get_master_ind_blk {
  my ($pofile, $master_ind_blk, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  #print "pofile=$pofile master_ind_blk=$master_ind_blk\n";

  my $buf;

  my @blocks = ();

  if (read_blk($pofile, $master_ind_blk, \$buf)) {
    dump_blk($buf) if $debug;
  }

  return @blocks;
}

# Parse index block (sapling file)
sub parse_ind_blk {
  my ($buf, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;
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
    my (@lo) = unpack "C256", $buf;
    #foreach my $byte (@lo) {
    #  print sprintf("%02x ", $byte);
    #}
    #print "\n";
    my (@hi) = unpack "x256C256", $buf;
    #foreach my $byte (@hi) {
    #  print sprintf("%02x ", $byte);
    #}
    #print "\n";
    for (my $b = 0; $b < 256; $b++) {
      #print sprintf("lo=%02x hi=%02x\n", $lo[$b], $hi[$b]);
      my $blk = ($hi[$b] << 8) | $lo[$b];
      #print sprintf("blk=%04x\n", $blk);
      push @blocks, $blk;
    }
  }

  return @blocks;
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

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volume_name, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files) = get_key_vol_dir_blk($pofile, $debug);

  my $found_it = 0;
  foreach my $file (@files) {
    #print "file=$file->{'filename'}\n";
    if ($file->{'filename'} eq $filename) {
      #print "FOUND IT!\n";
      $found_it = 1;
      $storage_type = $file->{'storage_type'};
      $file_type = $file->{'ftype'};
      $key_pointer = $file->{'keyptr'};
      $blocks_used = $file->{'used'};
      last;
    }
  }

  if (! $found_it) {
    my $vol_dir_blk = $nxt_vol_dir_blk;

    while ($vol_dir_blk) {
      my ($prv_vol_dir_blk, $nxt_vol_dir_blk, @files) = get_vol_dir_blk($pofile, $vol_dir_blk, $debug);

      foreach my $file (@files) {
        #print "file=$file->{'filename'}\n";
        if ($file->{'filename'} eq $filename) {
          #print "FOUND IT!\n";
          $found_it = 1;
          $storage_type = $file->{'storage_type'};
          $file_type = $file->{'ftype'};
          $key_pointer = $file->{'keyptr'};
          $blocks_used = $file->{'used'};
          last;
        }
      }
      $vol_dir_blk = $nxt_vol_dir_blk;
      last if $found_it;
    }
  }

  print "File not found\n" unless $found_it;

  return $storage_type, $file_type, $key_pointer, $blocks_used;
}

#
# Read a file
#
sub read_file {
  my ($pofile, $filename, $mode, $conv, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  print "pofile=$pofile filename=$filename mode=$mode conv=$conv\n" if $debug;

  my ($storage_type, $file_type, $key_pointer, $blocks_used) = find_file($pofile, $filename, $debug);

  return if $storage_type == 0;

  my $buf;

  print "storage_type=$storage_type file_type=$file_type key_pointer=$key_pointer blocks_used=$blocks_used\n" if $debug;

  # Seedling file, only 1 block
  if ($storage_type == 1) {
    my $buf2;

    if (read_blk($pofile, $key_pointer, \$buf2)) {
      #dump_blk($buf) if $debug;
      dump_blk($buf);
      my @bytes = unpack "C*", $buf2;
      foreach my $byte (@bytes) {
        # For text file translation.
        last if $byte == 0x00 && $mode eq 'T';
        # Translate \r to \n
        $byte = 0x0a if $byte == 0x8d && $conv;
        # Convert Apple II ASCII to standard ASCII (clear high bit)
        $byte &= 0x7f if $mode eq 'T';
        #print sprintf("%c", $byte & 0x7f);
        print sprintf("%c", $byte);
      }
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
        foreach my $byte (@bytes) {
          # For text file translation.
          last if $byte == 0x00 && $mode eq 'T';
          # Translate \r to \n
          $byte = 0x0a if $byte == 0x8d && $conv;
          # Convert Apple II ASCII to standard ASCII (clear high bit)
          $byte &= 0x7f if $mode eq 'T';
          #print sprintf("%c", $byte & 0x7f);
          print sprintf("%c", $byte);
        }
      }
      last if $blkno++ == $blocks_used - 1;
    }
  # Tree file, 257+ blocks
  } elsif ($storage_type == 3) {
    my @blks = get_master_ind_blk($pofile, $key_pointer, $debug);
    ##FIXME -- need to handle Tree files here.
  } else {
    print "Not a regular file!\n";
  }
}

#
# Parse volume bit map
#
sub parse_vol_bit_map {
  my ($buf, $dbg) = @_;

  my @blocks = ();

  my (@bytes) = unpack $vol_bit_map_tmpl, $buf;

  foreach my $byte (@bytes) {
    #print sprintf("%02x ", $byte);
    #print sprintf("%08b ", $byte);
    push @blocks, $byte;
  }
  print "\n";

  return @blocks;
}

#
# Get volume bit map
#
sub get_vol_bit_map {
  my ($pofile, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my ($prv_vol_dir_blk, $nxt_vol_dir_blk, $storage_type_name_length, $volname, $creation_ymd, $creation_hm, $version, $min_version, $access, $entry_length, $entries_per_block, $file_count, $bit_map_pointer, $total_blocks, @files) = get_key_vol_dir_blk($pofile, $debug);

  my $buf;

  #print sprintf("bit_map_pointer=%04x\n", $bit_map_pointer) if $debug;

  # Need to use total_blocks to calculate the number of volume bit map blocks.
  #print sprintf("total_blocks=%04x\n", $total_blocks);
  my $num_tracks = $total_blocks / 8;
  #print sprintf("num_tracks=%d\n", $num_tracks);
  my $num_vol_bit_map_blks = ceil($num_tracks / 512.0);
  #print sprintf("num_vol_bit_map_blks=%d\n", $num_vol_bit_map_blks);
  $num_vol_bit_map_blks = 1 if $num_vol_bit_map_blks < 1;
  #print sprintf("num_vol_bit_map_blks=%d\n", $num_vol_bit_map_blks);

  my @blocks = ();

  my $trk = 0;
  for (my $blk = $bit_map_pointer; $blk < $bit_map_pointer + $num_vol_bit_map_blks; $blk++) {
    clear_buf(\$buf);
    if (read_blk($pofile, $bit_map_pointer, \$buf)) {
      dump_blk($buf) if $debug;
      my (@blks) = parse_vol_bit_map($buf, $debug);
      foreach my $blk (@blks) {
        #print sprintf("%02x ", $blk);
        push @blocks, $blk;
        last if $trk++ >= $num_tracks;
      }
      #print "\n";
    }
  }

  return @blocks;
}

#
# Display blocks free map
#
sub freemap {
  my ($pofile, $dbg) = @_;

  $debug = 1 if defined $dbg && $dbg;

  my (@blocks) = get_vol_bit_map($pofile, $debug);

  print "    12345678\n";
  print "   +--------\n";

  my $trk = 0;
  foreach my $byte (@blocks) {
    my $bits = sprintf("%08b", $byte);
    $bits =~ s/[0]/ /g;
    $bits =~ s/[1]/\*/g;
    print sprintf("%2d |%s\n", $trk++, $bits);
  }
  print "\n";
}

1;

