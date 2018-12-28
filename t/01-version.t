#!/usr/bin/env perl6

use lib 'lib';
use Archive::Libarchive;
use Test;
plan 8;

constant AUTHOR = ?%*ENV<TEST_AUTHOR>;

if AUTHOR {
  my Archive::Libarchive $a .= new(operation => LibarchiveRead);
  my %vers = $a.lib-version;
  is %vers<ver>,     '3003003', 'libarchive version';
  is %vers<strver>,  'libarchive 3.3.3', 'libarchive version as string';
  is %vers<details>,
    'libarchive 3.3.3 zlib/1.2.11 liblzma/5.2.2 bz2lib/1.0.6 liblz4/1.8.2 libzstd/1.3.5',
    'libarchive version details';
  is %vers<liblzma>, '5.2.2', 'liblzma version';
  is %vers<liblz4>,  '1.8.2', 'liblz4 version';
  is %vers<bzlib>,   '1.0.6, 6-Sept-2010', 'bzlib version';
  is %vers<zlib>,    '1.2.11', 'zlib version';
  is %vers<libzstd>, '1.3.5', 'libzstd version';
}else{
  skip-rest 'Skipping author test';
  exit;
}
