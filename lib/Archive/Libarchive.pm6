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
constant ENTRY_ERROR            is export = 80;

class X::Libarchive is Exception
{
  has Int $.errno;
  has Str $.error;

  method message { "Error {$!errno}: $!error"; }
}

class Entry
{
  has archive_entry $.entry;
  has Int $!operation;

  submethod BUILD(Str :$path?, Int :$size?, Int :$filetype?, Int :$perm?, Int :$operation?)
  {
    if $operation ~~ LibarchiveWrite|LibarchiveOverwrite {
      $!entry = archive_entry_new;
      $!operation = $operation;
      if $path.defined {
        self.pathname: $path;
        self.size: $size // $path.IO.s;
        self.filetype: $filetype // AE_IFREG;
        self.perm: $perm // 0o644;
      }
    } else {
      $!entry = archive_entry.new;
      $!operation = LibarchiveRead;
    }
  }

  submethod DESTROY
  {
    archive_entry_free $!entry if $!entry.defined;
  }

  multi method pathname(Str $path)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_pathname $!entry, $path;
  }

  multi method pathname(--> Str)
  {
    archive_entry_pathname $!entry;
  }

  multi method size(Int $size)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_size $!entry, $size;
  }

  multi method size(--> int64)
  {
    archive_entry_size $!entry;
  }

  method filetype(Int $type)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_filetype $!entry, $type;
  }

  method perm(Int $perm)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_perm $!entry, $perm;
  }

  multi method atime(Int $atime)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_atime $!entry, $atime, 0;
  }

  multi method atime()
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_unset_atime $!entry;
  }

  multi method ctime(Int $ctime)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_ctime $!entry, $ctime, 0;
  }

  multi method ctime()
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_unset_ctime $!entry;
  }

  multi method mtime(Int $mtime)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_mtime $!entry, $mtime, 0;
  }

  multi method mtime()
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_unset_mtime $!entry;
  }

  multi method birthtime(Int $birthtime)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_birthtime $!entry, $birthtime, 0;
  }

  multi method birthtime()
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_unset_birthtime $!entry;
  }

  method uid(Int $uid)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_uid $!entry, $uid;
  }

  method gid(Int $gid)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_gid $!entry, $gid;
  }

  method uname(Str $uname)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_uname $!entry, $uname;
  }

  method gname(Str $gname)
  {
    if $!operation == LibarchiveRead {
      fail X::Libarchive.new: errno => ENTRY_ERROR, error => 'Read-only entry';
    }
    archive_entry_set_gname $!entry, $gname;
  }

  method free()
  {
    archive_entry_free $!entry;
    $!entry = Nil;
  }
}

has archive $.archive;
has Int $.operation;

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

method next-header(Archive::Libarchive::Entry:D $e! --> Bool)
{
  my $res = archive_read_next_header $!archive, $e.entry;
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
  my $e = Archive::Libarchive::Entry.new(:$!operation, :$file);
  $e.pathname($file);
  $e.size($size);
  $e.filetype($type);
  $e.perm($perm);
  $e.atime($atime);
  $e.ctime($ctime);
  $e.mtime($mtime);
  $e.birthtime($birthtime) if $birthtime.defined;
  $e.uid($uid) if $uid.defined;
  $e.gid($gid) if $gid.defined;
  $e.uname($uname) if $uname.defined;
  $e.gname($gname) if $gname.defined;
  my $res = archive_write_header $!archive, $e.entry;
  if $res != ARCHIVE_OK {
    fail X::Libarchive.new: errno => $res, error => archive_error_string($!archive);
  }
  $e.free;
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

multi method extract(Archive::Libarchive $ext!, &callback:(Archive::Libarchive::Entry $e --> Bool)! --> Bool)
{
  my $e = Archive::Libarchive::Entry.new;
  my Bool $res = False;
  while (my $rres = archive_read_next_header $!archive, $e.entry) == ARCHIVE_OK {
    last if $rres == ARCHIVE_EOF;
    if $rres != ARCHIVE_OK {
      fail X::Libarchive.new: errno => $rres, error => archive_error_string($!archive);
    }
    if &callback($e) {
      my $wres = archive_write_header $ext.archive, $e.entry;
      if $wres == ARCHIVE_OK {
        if $e.size > 0 {
          self!copy-data: $ext;
        }
      } else {
        fail X::Libarchive.new: errno => $wres, error => archive_error_string($!archive);
      }
      my $fres = archive_write_finish_entry $ext.archive;
      if $fres != ARCHIVE_OK {
        fail X::Libarchive.new: errno => $fres, error => archive_error_string($!archive);
      }
      $res = True;
    }
  }
  return $res;
}

multi method extract(Archive::Libarchive $ext! --> Bool)
{
  my $e = Archive::Libarchive::Entry.new;
  while (my $rres = archive_read_next_header $!archive, $e.entry) == ARCHIVE_OK {
    last if $rres == ARCHIVE_EOF;
    if $rres != ARCHIVE_OK {
      fail X::Libarchive.new: errno => $rres, error => archive_error_string($!archive);
    }
    my $wres = archive_write_header $ext.archive, $e.entry;
    if $wres == ARCHIVE_OK {
      if $e.size > 0 {
        self!copy-data: $ext;
      }
    } else {
      fail X::Libarchive.new: errno => $wres, error => archive_error_string($!archive);
    }
    my $fres = archive_write_finish_entry $ext.archive;
    if $fres != ARCHIVE_OK {
      fail X::Libarchive.new: errno => $fres, error => archive_error_string($!archive);
    }
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
