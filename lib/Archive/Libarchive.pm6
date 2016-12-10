use v6;
unit class Archive::Libarchive:ver<0.0.1>;

use Archive::Libarchive::Raw;
use Archive::Libarchive::Entry;
use NativeCall;

class X::Libarchive is Exception
{
  has Int $.errno;
  has Str $.error;

  method message { "Error {$!errno}: $!error"; }
}

enum LibarchiveOp  is export <LibarchiveRead LibarchiveWrite LibarchiveOverwrite>;
enum LibarchiveFormat is export <ARCHIVE_7ZIP ARCHIVE_AR ARCHIVE_BSD ARCHIVE_CAB ARCHIVE_CLASSIC
  ARCHIVE_CODE ARCHIVE_CPIO ARCHIVE_DUMP ARCHIVE_EMPTY ARCHIVE_GNUTAR ARCHIVE_ISO9660 ARCHIVE_LHA ARCHIVE_MTREE
  ARCHIVE_NEWC ARCHIVE_PAX ARCHIVE_RAR ARCHIVE_RAW ARCHIVE_RESTRICTED ARCHIVE_SHAR ARCHIVE_SVR4 ARCHIVE_TAR
  ARCHIVE_USTAR ARCHIVE_V7TAR ARCHIVE_WARC ARCHIVE_XAR ARCHIVE_ZIP>;
enum LibarchiveFilter is export <ARCHIVE_B64ENCODE ARCHIVE_BZIP2 ARCHIVE_COMPRESS ARCHIVE_GRZIP
  ARCHIVE_GZIP ARCHIVE_LRZIP ARCHIVE_LZ4 ARCHIVE_LZIP ARCHIVE_LZMA ARCHIVE_LZOP ARCHIVE_NONE ARCHIVE_PROGRAM
  ARCHIVE_RPM ARCHIVE_UU ARCHIVE_UUENCODE ARCHIVE_XZ>;

constant ARCHIVE_CREATE         is export = 10;
constant ARCHIVE_READ_FORMAT    is export = 20;
constant ARCHIVE_READ_FILTER    is export = 30;
constant ARCHIVE_WRITE_FORMAT   is export = 40;
constant ARCHIVE_WRITE_FILTER   is export = 50;
constant ARCHIVE_FILE_NOT_FOUND is export = 60;
constant ARCHIVE_FILE_FOUND     is export = 70;

our %readformat := {
  ARCHIVE_7ZIP    => &archive_read_support_format_7zip,
  ARCHIVE_AR      => &archive_read_support_format_ar,
  ARCHIVE_CODE    => &archive_read_support_format_by_code,
  ARCHIVE_CAB     => &archive_read_support_format_cab,
  ARCHIVE_CPIO    => &archive_read_support_format_cpio,
  ARCHIVE_EMPTY   => &archive_read_support_format_empty,
  ARCHIVE_GNUTAR  => &archive_read_support_format_gnutar,
  ARCHIVE_ISO9660 => &archive_read_support_format_iso9660,
  ARCHIVE_LHA     => &archive_read_support_format_lha,
  ARCHIVE_MTREE   => &archive_read_support_format_mtree,
  ARCHIVE_RAR     => &archive_read_support_format_rar,
  ARCHIVE_RAW     => &archive_read_support_format_raw,
  ARCHIVE_TAR     => &archive_read_support_format_tar,
  ARCHIVE_WARC    => &archive_read_support_format_warc,
  ARCHIVE_XAR     => &archive_read_support_format_xar,
  ARCHIVE_ZIP     => &archive_read_support_format_zip,
};
our %readfilter := {
  ARCHIVE_BZIP2    => &archive_read_support_filter_bzip2,
  ARCHIVE_COMPRESS => &archive_read_support_filter_compress,
  ARCHIVE_GZIP     => &archive_read_support_filter_gzip,
  ARCHIVE_GRZIP    => &archive_read_support_filter_grzip,
  ARCHIVE_LRZIP    => &archive_read_support_filter_lrzip,
  ARCHIVE_LZ4      => &archive_read_support_filter_lz4,
  ARCHIVE_LZIP     => &archive_read_support_filter_lzip,
  ARCHIVE_LZMA     => &archive_read_support_filter_lzma,
  ARCHIVE_LZOP     => &archive_read_support_filter_lzop,
  ARCHIVE_NONE     => &archive_read_support_filter_none,
  ARCHIVE_RPM      => &archive_read_support_filter_rpm,
  ARCHIVE_UU       => &archive_read_support_filter_uu,
  ARCHIVE_XZ       => &archive_read_support_filter_xz,
};
our %writeformat := {
  ARCHIVE_7ZIP       => &archive_write_set_format_7zip,
  ARCHIVE_BSD        => &archive_write_set_format_ar_bsd,
  ARCHIVE_SVR4       => &archive_write_set_format_ar_svr4,
  ARCHIVE_CPIO       => &archive_write_set_format_cpio,
  ARCHIVE_NEWC       => &archive_write_set_format_cpio_newc,
  ARCHIVE_GNUTAR     => &archive_write_set_format_gnutar,
  ARCHIVE_ISO9660    => &archive_write_set_format_iso9660,
  ARCHIVE_MTREE      => &archive_write_set_format_mtree,
  ARCHIVE_CLASSIC    => &archive_write_set_format_mtree_classic,
  ARCHIVE_PAX        => &archive_write_set_format_pax,
  ARCHIVE_RESTRICTED => &archive_write_set_format_pax_restricted,
  ARCHIVE_RAW        => &archive_write_set_format_raw,
  ARCHIVE_SHAR       => &archive_write_set_format_shar,
  ARCHIVE_DUMP       => &archive_write_set_format_shar_dump,
  ARCHIVE_USTAR      => &archive_write_set_format_ustar,
  ARCHIVE_V7TAR      => &archive_write_set_format_v7tar,
  ARCHIVE_WARC       => &archive_write_set_format_warc,
  ARCHIVE_XAR        => &archive_write_set_format_xar,
  ARCHIVE_ZIP        => &archive_write_set_format_zip,
};
our %writefilter := {
  ARCHIVE_B64ENCODE => &archive_write_add_filter_b64encode,
  ARCHIVE_BZIP2     => &archive_write_add_filter_bzip2,
  ARCHIVE_COMPRESS  => &archive_write_add_filter_compress,
  ARCHIVE_GRZIP     => &archive_write_add_filter_grzip,
  ARCHIVE_GZIP      => &archive_write_add_filter_gzip,
  ARCHIVE_LRZIP     => &archive_write_add_filter_lrzip,
  ARCHIVE_LZ4       => &archive_write_add_filter_lz4,
  ARCHIVE_LZIP      => &archive_write_add_filter_lzip,
  ARCHIVE_LZMA      => &archive_write_add_filter_lzma,
  ARCHIVE_LZOP      => &archive_write_add_filter_lzop,
  ARCHIVE_NONE      => &archive_write_add_filter_none,
  ARCHIVE_PROGRAM   => &archive_write_add_filter_program,
  ARCHIVE_UUENCODE  => &archive_write_add_filter_uuencode,
  ARCHIVE_XZ        => &archive_write_add_filter_xz,
};

has archive $.archive;
has Int $.operation is rw;
has Archive::Libarchive::Entry $.entry is rw;

submethod BUILD(LibarchiveOp :$operation!, LibarchiveFormat :$format?, LibarchiveFilter :$filter?, Any :$file?)
{
  $!operation = $operation;
  if $!operation == LibarchiveRead {
    $!archive = archive_read_new;
    if ! $!archive.defined {
      fail X::Libarchive.new: errno => ARCHIVE_CREATE, error => 'Error creating libarchive C struct';
    }
    if ! $format.defined {
      try {
        my $res = archive_read_support_format_all self.archive;
        die unless $res == ARCHIVE_OK;
        CATCH {
          fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
        }
      }
    }else{
      if %readformat{$format}:exists {
        try {
          my $res = %readformat{$format}(self.archive);
          die unless $res == ARCHIVE_OK;
          CATCH {
            fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
          }
        }
      }else{
        fail X::Libarchive.new: errno => ARCHIVE_READ_FORMAT, error => 'Unknown read format';
      }
    }
    if ! $filter.defined {
      try {
        my $res = archive_read_support_filter_all self.archive;
        die unless $res == ARCHIVE_OK;
        CATCH {
          fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
        }
      }
    }else{
      if %readfilter{$filter}:exists {
        try {
          my $res = %readfilter{$filter}(self.archive);
          die unless $res == ARCHIVE_OK;
          CATCH {
            fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
          }
        }
      }else{
        fail X::Libarchive.new: errno => ARCHIVE_READ_FILTER, error => 'Unknown read filter';
      }
    }
  } elsif $!operation ~~ LibarchiveWrite|LibarchiveOverwrite {
    $!archive = archive_write_new;
    if ! $!archive.defined {
      fail X::Libarchive.new: errno => ARCHIVE_CREATE, error => 'Error creating libarchive C struct';
    }
    # TODO format, filter, and compression
  } else {
    fail X::Libarchive.new: errno => ARCHIVE_CREATE, error => 'Wrong operation mode';
  }
  if $file.defined {
    self.open: $file;
  }
}

submethod DESTROY
{
  if self.archive.defined {
    if self.operation == LibarchiveRead {
      archive_read_close self.archive;
      archive_read_free  self.archive;
    } elsif self.operation == LibarchiveWrite {
      archive_write_close self.archive;
      archive_write_free  self.archive;
    }
  }
}

multi method open(Str $filename where ! .IO.f, Int $size = 10240)
{
  if self.operation ~~ LibarchiveWrite|LibarchiveOverwrite {
    try {
      my $res = archive_write_open_filename self.archive, $filename;
      CATCH {
        fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
      }
    }
  } elsif self.operation == LibarchiveRead {
    fail X::Libarchive.new: errno => ARCHIVE_FILE_NOT_FOUND, error => 'File not found';
  }
}

multi method open(Str $filename where .IO.f, Int $size = 10240)
{
  if self.operation == LibarchiveRead {
    try {
      my $res = archive_read_open_filename self.archive, $filename, $size;
      CATCH {
        fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
      }
    }
  } elsif self.operation == LibarchiveWrite {
    fail X::Libarchive.new: errno => ARCHIVE_FILE_FOUND, error => 'File already present';
  } elsif self.operation == LibarchiveOverwrite {
    try {
      my $res = archive_write_open_filename self.archive, $filename;
      CATCH {
        fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
      }
    }
  }
}

multi method open(Buf $data)
{
  try {
    my $res = archive_read_open_memory self.archive, $data, $data.bytes;
    CATCH {
      fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
    }
  }
}

method next-header(--> Bool)
{
  if ! $!entry.defined {
    $!entry = Archive::Libarchive::Entry.new;
  }
  my $res;
  try {
    $res = archive_read_next_header self.archive, self.entry.entry;
    CATCH {
      fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
    }
  }
  return $res == ARCHIVE_OK ?? True !! False;
}

method data-skip
{
  try {
    my $res = archive_read_data_skip self.archive;
    CATCH {
      fail X::Libarchive.new: errno => $res, error => archive_error_string(self.archive);
    }
  }
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
