#!/usr/bin/env perl6

use lib 'lib';
use Archive::Libarchive;

sub MAIN(Str :$file! where { .IO.f // die "file '$file' not found" })
{
  my $buffer = slurp $file, :bin;
  my $a = Archive::Libarchive.new: operation => LibarchiveRead, file => $buffer;
  my Archive::Libarchive::Entry $e .= new;
  while $a.next-header($e) {
    say "{$e.pathname} {$e.size}";
    $a.data-skip;
  }
  $a.close;
}
