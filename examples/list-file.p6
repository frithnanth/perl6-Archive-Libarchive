#!/usr/bin/env perl6

use lib 'lib';
use Archive::Libarchive;

sub MAIN(Str :$file! where { .IO.f // die "file '$file' not found" })
{
  my Archive::Libarchive $a .= new: operation => LibarchiveRead, file => $file;
  while $a.next-header {
    $a.entry.pathname.say;
    $a.data-skip;
  }
}
