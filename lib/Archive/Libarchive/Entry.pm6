use v6;
unit class Archive::Libarchive::Entry:ver<0.0.1>;

use Archive::Libarchive::Raw;
use NativeCall;

has archive_entry $.entry;

submethod BUILD(Str $path?, Int $size?, Int $filetype?, Int $perm?)
{
  $!entry = archive_entry.new;
  # TODO when creating an archive one may specify path, size, etc.
}

method pathname(--> Str)
{
  my $res;
  try {
    $res = archive_entry_pathname self.entry;
    CATCH {
      fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
    }
  }
  return $res;
}

