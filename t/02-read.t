#!/usr/bin/env perl6

use Test;
use lib 'lib';
use Archive::Libarchive;

my Archive::Libarchive $a .= new: operation => LibarchiveRead;
is $a.WHAT, Archive::Libarchive, 'Create object for reading';
throws-like
  { $a.open: 'notafile' },
  X::Libarchive,
  message => /'File not found'/,
  'Open file fails';
my $path = $*PROGRAM-NAME.subst(/ <-[/]>+$/, '');
lives-ok { $a.open: $path ~ 'test.tar.gz' }, 'Open file succeedes';
my Archive::Libarchive::Entry $e .= new;
is $a.next-header($e), True, 'Read first entry from file';
is $e.pathname, 'test1', 'Entry pathname from file';
lives-ok { $a.data-skip }, 'Skip file data';
my $buffer = slurp $path ~ 'test.tar.gz', :bin;
my $am = Archive::Libarchive.new: operation => LibarchiveRead, file => $buffer;
is $am.WHAT, Archive::Libarchive, 'Create object for reading from memory';
is $am.next-header($e), True, 'Read first entry from memory';
is $e.pathname, 'test1', 'Entry pathname from memory';
lives-ok { $am.close }, 'Close archive';
my Archive::Libarchive $a1 .= new: operation => LibarchiveRead, file => 't/test.tar.gz';
my $content = $a1.read-file-content(sub (Archive::Libarchive::Entry $e --> Bool) { $e.pathname eq 'test2' });
is $content.decode('utf-8'), "test2\n", 'Read a file into a variable';
fails-like
  { $a1.read-file-content(sub (Archive::Libarchive::Entry $e --> Bool) { $e.pathname eq 'notest' }) },
  X::Libarchive,
  message => /'No such entry found'/,
  'Open file fails';

done-testing;
