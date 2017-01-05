#!/usr/bin/env perl6

use lib 'lib';
use Archive::Libarchive;
use Archive::Libarchive::Constants;

sub MAIN(:$file! where { .IO.f // die "file '$file' not found" })
{
  my Archive::Libarchive $a .= new:
      operation => LibarchiveRead,
      file => $file;
  my Archive::Libarchive $ext .= new:
      operation => LibarchiveExtract,
      flags => ARCHIVE_EXTRACT_TIME +| ARCHIVE_EXTRACT_PERM +| ARCHIVE_EXTRACT_ACL +| ARCHIVE_EXTRACT_FFLAGS;
  try {
    $a.extract: $ext;
    CATCH {
      say "Can't extract files: $_";
    }
  }
  $a.close;
  $ext.close;
}
