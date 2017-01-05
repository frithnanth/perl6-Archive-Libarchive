#!/usr/bin/env perl6

use Test;
use lib 'lib';
use Archive::Libarchive;
use Archive::Libarchive::Constants;

my $path = $*PROGRAM-NAME.subst(/ <-[/]>+$/, '');
my $filein = $path ~ 'test.tar.gz';
my Archive::Libarchive $a .= new:
    operation => LibarchiveRead,
    file => $filein;
is $a.WHAT, Archive::Libarchive, 'Create object for reading';
my Archive::Libarchive $ext .= new:
    operation => LibarchiveExtract,
    flags => ARCHIVE_EXTRACT_TIME +| ARCHIVE_EXTRACT_PERM +| ARCHIVE_EXTRACT_ACL +| ARCHIVE_EXTRACT_FFLAGS;
is $ext.WHAT, Archive::Libarchive, 'Create object to extract files';
is $a.extract($ext), True, 'Extract all files';


lives-ok { $a.close }, 'Close first archive object';
lives-ok { $ext.close }, 'Close second archive object';

done-testing;
