#!/usr/bin/env perl6

use Test;
use lib 'lib';
use Archive::Libarchive;
use Archive::Libarchive::Constants;

my $path = $*PROGRAM-NAME.subst(/ <-[/]>+$/, '');
my $filein = $path ~ 'test.tar.gz';
my Archive::Libarchive $a .= new:
    operation => LibarchiveExtract,
    file => $filein,
    flags => ARCHIVE_EXTRACT_TIME +| ARCHIVE_EXTRACT_PERM +| ARCHIVE_EXTRACT_ACL +| ARCHIVE_EXTRACT_FFLAGS;
is $a.WHAT, Archive::Libarchive, 'Create object for extract';
is $a.extract, True, 'Extract all files';
lives-ok { $a.close }, 'Close archive object';
'test1'.IO.unlink;
'test2'.IO.unlink;
'test3'.IO.unlink;
my Archive::Libarchive $a2 .= new:
    operation => LibarchiveExtract,
    file => $filein,
    flags => ARCHIVE_EXTRACT_TIME +| ARCHIVE_EXTRACT_PERM +| ARCHIVE_EXTRACT_ACL +| ARCHIVE_EXTRACT_FFLAGS;
$a2.extract(sub (Archive::Libarchive::Entry $e --> Bool) { $e.pathname eq 'test2' });
ok ! 'test1'.IO.e && 'test2'.IO.e && ! 'test3'.IO.e, 'Extract one file';
'test2'.IO.unlink;
$a2.close;

done-testing;
