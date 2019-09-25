#!/usr/bin/env perl6

use Test;
use lib 'lib';
use Archive::Libarchive;
use experimental :pack;

my Archive::Libarchive $a .= new: operation => LibarchiveWrite;
is $a.WHAT, Archive::Libarchive, 'Create object for writing';
my $path = $*PROGRAM-NAME.subst(/ <-[/]>+$/, '');
throws-like
  { $a.open: $path ~ 'test.tar.gz' },
  X::Libarchive,
  message => /'File already present'/,
  'Open file fails';
my $fileout = $path ~ 'test1.tar.gz';
$fileout.IO.unlink if $fileout.IO.e;
lives-ok { $a.open: $fileout, format => 'gnutar', filters => ['gzip'] }, 'Open file succeedes';
$a.close;
$fileout.IO.unlink;

my Archive::Libarchive $a2 .= new: operation => LibarchiveWrite;
$fileout.IO.unlink if $fileout.IO.e;
$a2.open: $fileout, format => 'gnutar', filters => ['gzip'];
$a2.write-header($*PROGRAM-NAME);
my Buf $data .= new(pack 'A*', $*PROGRAM-NAME.IO.slurp);
is $a2.write-data($data), True, 'Write data from buffer';
$a2.close;
$fileout.IO.unlink;


my Archive::Libarchive $a3 .= new:
  operation => LibarchiveWrite,
  file => $fileout,
  format => 'gnutar',
  filters => ['gzip'];
is $a3.WHAT, Archive::Libarchive, 'Create object and file for writing';
$a3.close;

my Archive::Libarchive $ao .= new:
  operation => LibarchiveOverwrite,
  file => $fileout,
  format => 'gnutar',
  filters => ['gzip'];
is $ao.WHAT, Archive::Libarchive, 'Create object and file for overwriting';
is $ao.write-header($*PROGRAM-NAME), True, 'Write header';
is $ao.write-data($*PROGRAM-NAME), True, 'Write data from file';
lives-ok { $ao.close }, 'Close archive';
$fileout.IO.unlink;

done-testing;
