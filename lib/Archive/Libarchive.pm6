use v6;
unit class Archive::Libarchive:ver<0.0.1>;

use NativeCall;
use Archive::Libarchive::Raw;
use Archive::Libarchive::Constants;

enum LibarchiveOp  is export <LibarchiveRead LibarchiveWrite LibarchiveOverwrite LibarchiveExtract>;

constant ARCHIVE_CREATE         is export = 10;
constant ARCHIVE_READ_FORMAT    is export = 20;
constant ARCHIVE_READ_FILTER    is export = 30;
constant ARCHIVE_WRITE_FORMAT   is export = 40;
constant ARCHIVE_WRITE_FILTER   is export = 50;
constant ARCHIVE_FILE_NOT_FOUND is export = 60;
constant ARCHIVE_FILE_FOUND     is export = 70;

class X::Libarchive is Exception
{
  has Int $.errno;
  has Str $.error;

  method message { "Error {$!errno}: $!error"; }
}

class Entry
{
  has archive_entry $.entry;

  submethod BUILD(Str :$path?, Int :$size?, Int :$filetype?, Int :$perm?, Int :$operation?)
  {
    if $operation ~~ LibarchiveWrite|LibarchiveOverwrite {
      $!entry = archive_entry_new;
    } else {
      $!entry = archive_entry.new;
    }
    if $path.defined {
      self.pathname: $path;
      self.size: $size // $path.IO.s;
      self.filetype: $filetype // AE_IFREG;
      self.perm: $perm // 0o644;
    }
  }

  multi method pathname(Str $path)
  {
    archive_entry_set_pathname $!entry, $path;
  }

  multi method pathname(--> Str)
  {
    archive_entry_pathname $!entry;
  }

  multi method size(Int $size)
  {
    archive_entry_set_size $!entry, $size;
  }

  multi method size(--> int64)
  {
    archive_entry_size $!entry;
  }

  method filetype(Int $type)
  {
    archive_entry_set_filetype $!entry, $type;
  }

  method perm(Int $perm)
  {
    archive_entry_set_perm $!entry, $perm;
  }

  multi method atime(Int $atime)
  {
    archive_entry_set_atime $!entry, $atime, 0;
  }

  multi method atime()
  {
    archive_entry_unset_atime $!entry;
  }

  multi method ctime(Int $ctime)
  {
    archive_entry_set_ctime $!entry, $ctime, 0;
  }

  multi method ctime()
  {
    archive_entry_unset_ctime $!entry;
  }

  multi method mtime(Int $mtime)
  {
    archive_entry_set_mtime $!entry, $mtime, 0;
  }

  multi method mtime()
  {
    archive_entry_unset_mtime $!entry;
  }

  multi method birthtime(Int $birthtime)
  {
    archive_entry_set_birthtime $!entry, $birthtime, 0;
  }

  multi method birthtime()
  {
    archive_entry_unset_birthtime $!entry;
  }

  method uid(Int $uid)
  {
    archive_entry_set_uid $!entry, $uid;
  }

  method gid(Int $gid)
  {
    archive_entry_set_gid $!entry, $gid;
  }

  method uname(Str $uname)
  {
    archive_entry_set_uname $!entry, $uname;
  }

  method gname(Str $gname)
  {
    archive_entry_set_gname $!entry, $gname;
  }

  method free()
  {
    archive_entry_free $!entry;
  }
}

has archive $.archive;
has Int $.operation;
has Archive::Libarchive::Entry $.entry;

submethod BUILD(LibarchiveOp :$operation!, Any :$file?, Int :$flags?)
{
  $!operation = $operation;
  if $!operation == LibarchiveRead {
    $!archive = archive_read_new;
    if ! $!archive.defined {
      fail X::Libarchive.new: errno => ARCHIVE_CREATE, error => 'Error creating libarchive C struct';
    }
    my $res = archive_read_support_format_all $!archive;
    if $res != ARCHIVE_OK {
      fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
    }
    $res = archive_read_support_filter_all $!archive;
    if $res != ARCHIVE_OK {
      fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
    }
  } elsif $!operation ~~ LibarchiveWrite|LibarchiveOverwrite {
    $!archive = archive_write_new;
    if ! $!archive.defined {
      fail X::Libarchive.new: errno => ARCHIVE_CREATE, error => 'Error creating libarchive C struct';
    }
  } elsif $!operation == LibarchiveExtract {
    $!archive = archive_write_disk_new;
    if ! $!archive.defined {
      fail X::Libarchive.new: errno => ARCHIVE_CREATE, error => 'Error creating libarchive C struct';
    }
    if $flags.defined {
      self.extract-opts: $flags;
    }
  } else {
    fail X::Libarchive.new: errno => ARCHIVE_CREATE, error => 'Wrong operation mode';
  }
  if $file.defined && $!operation != LibarchiveExtract {
    self.open: $file;
  }
}

method close
{
  if $!archive.defined {
    if $!operation == LibarchiveRead {
      my $res = archive_read_close $!archive;
      fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
      $res = archive_read_free  $!archive;
      fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
    } elsif $!operation ~~ LibarchiveWrite|LibarchiveOverwrite|LibarchiveExtract {
      my $res = archive_write_close $!archive;
      fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
      $res = archive_write_free  $!archive;
      fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
    }
  }
}

multi method extract-opts()
{
  callwith ARCHIVE_EXTRACT_TIME +| ARCHIVE_EXTRACT_PERM +| ARCHIVE_EXTRACT_ACL +| ARCHIVE_EXTRACT_FFLAGS;
}

multi method extract-opts(Int $flags!)
{
  if $!operation == LibarchiveExtract {
    my $res = archive_write_disk_set_options $!archive, $flags;
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
    $res = archive_write_disk_set_standard_lookup $!archive;
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
  }
}

multi method open(Str $filename where ! .IO.f, Int $size = 10240)
{
  if $!operation ~~ LibarchiveWrite|LibarchiveOverwrite {
    my $res = archive_write_set_format_filter_by_ext $!archive, $filename;
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
    $res = archive_write_open_filename $!archive, $filename;
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
  } elsif $!operation == LibarchiveRead {
    fail X::Libarchive.new: errno => ARCHIVE_FILE_NOT_FOUND, error => 'File not found';
  }
}

multi method open(Str $filename where .IO.f, Int $size = 10240)
{
  if $!operation == LibarchiveRead {
    my $res = archive_read_open_filename $!archive, $filename, $size;
    if $res != ARCHIVE_OK {
      fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
    }
  } elsif $!operation == LibarchiveWrite {
    fail X::Libarchive.new: errno => ARCHIVE_FILE_FOUND, error => 'File already present';
  } elsif $!operation == LibarchiveOverwrite {
    my $res = archive_write_set_format_filter_by_ext $!archive, $filename;
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
    $res = archive_write_open_filename $!archive, $filename;
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive) unless $res == ARCHIVE_OK;
  }
}

multi method open(Buf $data)
{
  my $res = archive_read_open_memory $!archive, $data, $data.bytes;
  if $res != ARCHIVE_OK {
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
  }
}

# FIXME Make it return the Entry object, so the user program can examine it
method next-header(--> Bool)
{
  if ! $!entry.defined {
    $!entry = Archive::Libarchive::Entry.new;
  }
  my $res = archive_read_next_header $!archive, $!entry.entry;
  if $res != (ARCHIVE_OK, ARCHIVE_EOF).any {
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
  }
  return $res == ARCHIVE_OK ?? True !! False;
}

method write-header(Str $file,
                    Int :$size? = $file.IO.s,
                    Int :$type? = AE_IFREG,
                    Int :$perm? = 0o644,
                    Int :$atime? = $file.IO.accessed.Int,
                    Int :$mtime? = $file.IO.modified.Int,
                    Int :$ctime? = $file.IO.changed.Int,
                    Int :$birthtime?,
                    Int :$uid?,
                    Int :$gid?,
                    Str :$uname?,
                    Str :$gname?
                    --> Bool)
{
  $!entry = Archive::Libarchive::Entry.new(:$!operation, :$file);
  $.entry.pathname($file);
  $.entry.size($size);
  $.entry.filetype($type);
  $.entry.perm($perm);
  $.entry.atime($atime);
  $.entry.ctime($ctime);
  $.entry.mtime($mtime);
  $.entry.birthtime($birthtime) if $birthtime.defined;
  $.entry.uid($uid) if $uid.defined;
  $.entry.gid($gid) if $gid.defined;
  $.entry.uname($uname) if $uname.defined;
  $.entry.gname($gname) if $gname.defined;
  my $res = archive_write_header $!archive, $!entry.entry;
  if $res != ARCHIVE_OK {
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
  }
  return True;
}

method write-data(Str $path --> Bool)
{
  my $fh = open $path, :r;
  my $res;
  while my $buffer = $fh.read(8192) {
    $res = archive_write_data($!archive, $buffer, $buffer.bytes);
    if $res < 0 {
      fail X::Libarchive.new: errno => - $res, error => archive_error_string($!archive);
    }
  }
  $fh.close;
  $.entry.free;
  return True;
}

method data-skip(--> Int)
{
  my $res = archive_read_data_skip $!archive;
  if $res != (ARCHIVE_OK, ARCHIVE_EOF).any {
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
  }
  return $res;
}

method !copy-data(Archive::Libarchive $ext! --> Bool)
{
  my $res;
  my $buff = Pointer[void].new;
  my int64 $size;
  my int64 $offset;
  loop {
    $res = archive_read_data_block $!archive, $buff, $size, $offset;
    return True if $res == ARCHIVE_EOF;
    if $res > ARCHIVE_OK {
      fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
    }
    $res = archive_write_data_block $ext.archive, $buff, $size, $offset;
    if $res > ARCHIVE_OK {
      fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
    }
  }
  return True;
}

multi method extract(Archive::Libarchive $ext!, Str :$regex! --> Bool)
{
}

multi method extract(Archive::Libarchive $ext!, Str $filename! --> Bool)
{
}

multi method extract(Archive::Libarchive $ext! --> Bool)
{
  if ! $!entry.defined {
    $!entry = Archive::Libarchive::Entry.new;
  }
  my $rres;
  while ($rres = archive_read_next_header $!archive, $!entry.entry) == ARCHIVE_OK {
    last if $rres == ARCHIVE_EOF;
    if $rres != ARCHIVE_OK {
      fail X::Libarchive.new: errno => $rres, error => archive_error_string($!archive);
    }
    my $wres = archive_write_header $ext.archive, $!entry.entry;
    if $wres == ARCHIVE_OK {
      if $.entry.size > 0 {
        self!copy-data: $ext;
      }
    } else {
      fail X::Libarchive.new: errno => $wres, error => archive_error_string($!archive);
    }
    my $fres = archive_write_finish_entry $ext.archive;
    fail X::Libarchive.new: errno => $fres, error => archive_error_string($!archive) if $fres != ARCHIVE_OK;
  }

  return True;
}

method lib-version
{
  {
    ver     => archive_version_number,
    strver  => archive_version_string,
    details => archive_version_details,
    zlib    => archive_zlib_version,
    liblzma => archive_liblzma_version,
    bzlib   => archive_bzlib_version,
    liblz4  => archive_liblz4_version,
  }
}

=begin pod

=head1 NAME

Archive::Libarchive - High-level bindings to libarchive

=head1 SYNOPSIS
=begin code

use v6;

use Archive::Libarchive;

sub MAIN(:$file! where { .IO.f // die "file '$file' not found" })
{
}

=end code

=head1 DESCRIPTION

B<Archive::Libarchive> provides a procedural and a OO interface to libarchive using Archive::Libarchive::Raw.

As the Libarchive site (L<http://www.libarchive.org/>) states, its implementation is able to:

=item Read a variety of formats, including tar, pax, cpio, zip, xar, lha, ar, cab, mtree, rar, and ISO images.
=item Write tar, pax, cpio, zip, xar, ar, ISO, mtree, and shar archives.
=item Handle automatically archives compressed with gzip, bzip2, lzip, xz, lzma, or compress.

=head1 Prerequisites

This module requires the libarchive library to be installed. Please follow the
instructions below based on your platform:

=head2 Debian Linux

=begin code
sudo apt-get install libarchive13
=end code

The module uses Archive::Libarchive::Raw which looks for a library called libarchive.so, or whatever it finds in
the environment variable B<PERL6_LIBARCHIVE_LIB> (provided that the library one chooses uses the same API).

=head1 Installation

To install it using Panda (a module management tool):

=begin code
$ panda update
$ panda install Archive::Libarchive
=end code

To install it using zef (a module management tool):

=begin code
$ zef update
$ zef install Archive::Libarchive
=end code

=head1 Testing

To run the tests:

=begin code
$ prove -e "perl6 -Ilib"
=end code

or

=begin code
$ prove6
=end code

=head1 Author

Fernando Santagata

=head1 License

The Artistic License 2.0

=end pod
