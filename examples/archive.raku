#!/usr/bin/env raku

use lib 'lib';
use Archive::Libarchive;
use Archive::Libarchive::Constants;

sub MAIN($fileo! where { ! .IO.f || die "file '$fileo' already present" },
         *@filei where { $_.all ~~ .IO.f || die "One of ( $_ ) not found" } )
{
  my Archive::Libarchive $a .= new: operation => LibarchiveWrite, file => $fileo;
  for @filei -> $file {
    try {
      $a.write-header($file,
                      uname => 'user1',
                      gname => 'group1',
                      filetype => ($file.IO.l ?? AE_IFLNK !! AE_IFREG)
                     );
      $a.write-data($file);
      CATCH {
        default { .Str.say }
      }
    }
  }
  $a.close;
}
