#!/usr/bin/env perl6

use lib 'lib';
use Archive::Libarchive;
use Archive::Libarchive::Constants;

sub MAIN(:$archive! where { .IO.f // die "file '$archive' not found" }, Str :$file!)
{
  my Archive::Libarchive $a .= new: operation => LibarchiveRead, file => $archive;
  my $content = $a.read-file-content(sub (Archive::Libarchive::Entry $e --> Bool) { $e.pathname eq $file });
  say $content.decode('utf-8');
}
