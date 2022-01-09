#!/usr/bin/env raku

use lib 'lib';
use Archive::Libarchive;
use Archive::Libarchive::Constants;

sub MAIN(:$archive! where { .IO.f // die "file '$archive' not found" }, Str :$file!)
{
  my Archive::Libarchive $a .= new: operation => LibarchiveRead, file => $archive;
  my Archive::Libarchive::Entry $e .= new;
  while $a.next-header($e) {
    $a.read-file-content($e).decode('utf-8').say if $e.pathname eq $file;
    $a.data-skip;
  }
  $a.close;
}
