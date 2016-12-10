#!/usr/bin/env perl6

use Test;
use lib 'lib';
use Archive::Libarchive;

my Archive::Libarchive $a .= new: operation => LibarchiveWrite;
is $a.WHAT, Archive::Libarchive, 'Create object for writing';

done-testing;
