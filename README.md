[![Actions Status](https://github.com/frithnanth/perl6-Archive-Libarchive/workflows/test/badge.svg)](https://github.com/frithnanth/perl6-Archive-Libarchive/actions)

NAME
====

Archive::Libarchive - High-level bindings to libarchive

SYNOPSIS
========

```raku
use v6;

use Archive::Libarchive;
use Archive::Libarchive::Constants;

sub MAIN(:$file! where { .IO.f // die "file '$file' not found" })
{
  my Archive::Libarchive $a .= new:
      operation => LibarchiveExtract,
      file => $file,
      flags => ARCHIVE_EXTRACT_TIME +| ARCHIVE_EXTRACT_PERM +| ARCHIVE_EXTRACT_ACL +| ARCHIVE_EXTRACT_FFLAGS;
  try {
    $a.extract: sub (Archive::Libarchive::Entry $e --> Bool) { $e.pathname eq 'test2' };
    CATCH {
      say "Can't extract files: $_";
    }
  }
  $a.close;
}
```

For more examples see the `example` directory.

DESCRIPTION
===========

**Archive::Libarchive** provides an OO interface to libarchive using Archive::Libarchive::Raw.

As the Libarchive site ([http://www.libarchive.org/](http://www.libarchive.org/)) states, its implementation is able to:

  * Read a variety of formats, including tar, pax, cpio, zip, xar, lha, ar, cab, mtree, rar, and ISO images.

  * Write tar, pax, cpio, zip, xar, ar, ISO, mtree, and shar archives.

  * Handle automatically archives compressed with gzip, bzip2, lzip, xz, lzma, or compress.

new(LibarchiveOp :$operation!, Any :$file?, Int :$flags?, Str :$format?, :@filters?)
------------------------------------------------------------------------------------

Creates an **Archive::Libarchive** object. It takes one *mandatory* argument: `operation`, what kind of operation will be performed.

The list of possible operations is provided by the `LibarchiveOp` enum:

  * `LibarchiveRead`: open the archive to list its content.

  * `LibarchiveWrite`: create a new archive. The file must not be already present.

  * `LibarchiveOverwrite`: create a new archive. The file will be overwritten if present.

  * `LibarchiveExtract`: extract the archive content.

When extracting one can specify some options to be applied to the newly created files. The default options are:

`ARCHIVE_EXTRACT_TIME +| ARCHIVE_EXTRACT_PERM +| ARCHIVE_EXTRACT_ACL +| ARCHIVE_EXTRACT_FFLAGS`

Those constants are defined in Archive::Libarchive::Constants, part of the Archive::Libarchive::Raw distribution. More details about those operation modes can be found on the libarchive site: [http://www.libarchive.org/](http://www.libarchive.org/)

If the optional argument `$file` is provided, then it will be opened; if not provided during the initialization, the program must call the `open` method later.

If the optional `$format` argument is provided, then the object will select that specific format while dealing with the archive.

List of possible read formats:

  * 7zip

  * ar

  * cab

  * cpio

  * empty

  * gnutar

  * iso9660

  * lha

  * mtree

  * rar

  * raw

  * tar

  * warc

  * xar

  * zip

List of possible write formats:

  * 7zip

  * ar

  * cpio

  * gnutar

  * iso9660

  * mtree

  * pax

  * raw

  * shar

  * ustar

  * v7tar

  * warc

  * xar

  * zip

If the optional `@filters` parameter is provided, then the object will add those filter to the archive. Multiple filters can be specified, so a program can manage a file.tar.gz.uu for example. The order of the filters is significant, in order to correctly deal with such files as *file.tar.uu.gz* and *file.tar.gz.uu*.

List of possible read filters:

  * bzip2

  * compress

  * gzip

  * grzip

  * lrzip

  * lz4

  * lzip

  * lzma

  * lzop

  * none

  * rpm

  * uu

  * xz

List of possible write filters:

  * b64encode

  * bzip2

  * compress

  * grzip

  * gzip

  * lrzip

  * lz4

  * lzip

  * lzma

  * lzop

  * none

  * uuencode

  * xz

### Note

Recent versions of libarchive implement an automatic way to determine the best mix of format and filters. If one's using a pretty recent libarchive, both $format and @filters may be omitted: the **new** method will determine automatically the right combination of parameters. Older versions though don't have that capability and the programmer has to define explicitly both parameters.

open(Str $filename!, Int :$size?, :$format?, :@filters?)
--------------------------------------------------------

open(Buf $data!)
----------------

Opens an archive; the first form is used on files, while the second one is used to open an archive that resides in memory. The first argument is always mandatory, while the other ones might been omitted. `$size` is the size of the internal buffer and defaults to 10240 bytes.

**Note:** this module does't apply `$*CWD` to the file name under the hood, so this will create a file in the original directory.

```raku
use Archive::Libarchive;

my Archive::Libarchive $a .= new: operation => LibarchiveWrite;
chdir 'subdir';
$a.open: 'file.tar.gz', format => 'gnutar', filters => ['gzip'];
…
```

close
-----

Closes the internal archive object, frees the memory and cleans up.

extract-opts(Int $flags?)
-------------------------

Sets the options for the files created when extracting files from an archive. The default options are:

`ARCHIVE_EXTRACT_TIME +| ARCHIVE_EXTRACT_PERM +| ARCHIVE_EXTRACT_ACL +| ARCHIVE_EXTRACT_FFLAGS`

next-header(Archive::Libarchive::Entry:D $e! --> Bool)
------------------------------------------------------

When reading an archive this method fills the Entry object and returns True till it reaches the end of the archive.

The Entry object is pubblicly defined inside the Archive::Libarchive module. It's initialized this way:

```raku
my Archive::Libarchive::Entry $e .= new;
```

So a complete archive lister can be implemented in few lines:

```raku
use Archive::Libarchive;

sub MAIN(Str :$file! where { .IO.f // die "file '$file' not found" })
{
  my Archive::Libarchive $a .= new: operation => LibarchiveRead, file => $file;
  my Archive::Libarchive::Entry $e .= new;
  while $a.next-header($e) {
    $e.pathname.say;
    $a.data-skip;
  }
  $a.close;
}
```

data-skip(--> Int)
------------------

When reading an archive this method skips file data to jump to the next header. It returns `ARCHIVE_OK` or `ARCHIVE_EOF` (defined in Archive::Libarchive::Constants)

read-file-content(Archive::Libarchive::Entry $e! --> Buf)
---------------------------------------------------------

This method reads the content of a file represented by its Entry object and returns it.

write-header(Str $file, Str :$pathname?, Int :$size?, Int :$filetype?, Int :$perm?, Int :$atime?, Int :$mtime?, Int :$ctime?, Int :$birthtime?, Int :$uid?, Int :$gid?, Str :$uname?, Str :$gname? --> Bool)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

When creating an archive this method writes the header entry for the file being inserted into the archive. The only mandatory argument is the file name, every other argument has a reasonable default. If the being inserted into the archive is a symbolic link, the target will be composed as a pathname relative to the base directory of the file, not as a full pathname. More details can be found on the libarchive site.

Each optional argument is available as a method of the Archive::Libarchive::Entry object and it can be set when needed.

*Note* `write-header` has a lot of optional arguments whose values are collected from the file one is adding to the archive. When using the second form of `write-data` one has to provide at least these arguments:

  * $size

  * $atime

  * $mtime

  * $ctime

For example:

```raku
$a.write-header($filename,
                :size($buffer.bytes),
                :atime(now.Int),
                :mtime(now.Int),
                :ctime(now.Int));
```

write-data(Str $path --> Bool)
------------------------------

write-data(Buf $data --> Bool)
------------------------------

When creating an archive this method writes the data for the file being inserted into the archive. `$path` is the pathname of the file to be archived, while `$data` is a data buffer.

extract(Str $destpath? --> Bool)
--------------------------------

extract(&callback:(Archive::Libarchive::Entry $e --> Bool)!, Str $destpath? --> Bool)
-------------------------------------------------------------------------------------

When extracting files from an archive this method does all the dirty work. If used in the first form it extracts all the files. The second form takes a callback function, which receives a Archive::Libarchive::Entry object.

For example, this will extract only the file whose name is *test2*:

```raku
$a.extract: sub (Archive::Libarchive::Entry $e --> Bool) { $e.pathname eq 'test2' };
```

In both cases one can specify the directory into which the files will be extracted.

lib-version
-----------

Returns a hash with the version number of libarchive and of each library used internally.

Archive::Libarchive::Entry
==========================

This class encapsulate an entry of the archive. It provides the following methods.

### pathname(Str $path)

### pathname(--> Str)

Sets or gets a pathname.

### size(Int $size)

### size(--> int64)

Sets or gets the object's size.

### filetype(Int $type)

### filetype(--> int64)

### filetype(:$decode where :so --> List)

Sets or gets the object's file type. If the first form of the getter is used a bit-mapped value is returned, that can be queried using the AE_* constants defined in Archive::Libarchive::Constants. If the second form of the getter is used a list is returned, which contain True or False values for each possible file type, listed in the following order:

  * regular file

  * directory

  * symbolic link

  * socket

  * character device

  * block device

  * fifo (named pipe)

This module exports several subs to test the file type:

### is-file(Int $val --> Bool)

### is-dir(Int $val --> Bool)

### is-link(Int $val --> Bool)

### is-sock(Int $val --> Bool)

### is-chr(Int $val --> Bool)

### is-blk(Int $val --> Bool)

### is-fifo(Int $val --> Bool)

### mode(Int $mode)

### mode(--> int64)

Sets or gets the object's mode.

### perm(Int $perm)

### perm(--> int64)

Sets or gets the object's permissions.

### atime(Int $atime)

### atime(--> int64)

Sets or gets the object's access time.

### ctime(Int $ctime)

### ctime(--> int64)

Sets or gets the object's change time.

### mtime(Int $mtime)

### mtime(--> int64)

Sets or gets the object's modification time.

### birthtime(Int $birthtime)

### birthtime()

Sets or resets the object's birth time.

### uid(Int $uid)

### uid(--> int64)

Sets or gets the object's uid.

### gid(Int $gid)

### gid(--> int64)

Sets or gets the object's gid.

### uname(Str $uname)

### uname(--> Str)

Sets or gets the object's user name.

### gname(Str $gname)

### gname(--> Str)

Sets or gets the object's group name.

Errors
======

When the underlying library returns an error condition, the methods will return a Failure object, which can be trapped and the exception can be analyzed and acted upon.

The exception object has two fields: `$errno` and `$error`, and return a message stating the error number and the associated message as delivered by libarchive.

Prerequisites
=============

This module requires the libarchive library to be installed. Please follow the instructions below based on your platform:

Debian Linux
------------

    sudo apt-get install libarchive13

The module uses Archive::Libarchive::Raw which looks for a library called libarchive.so.

Installation
============

To install it using zef (a module management tool):

    $ zef update
    $ zef install Archive::Libarchive

Author
======

Fernando Santagata

Contributions
=============

Many thanks to Haythem Elganiny for implementing some multi methods in the **Entry** class.

License The Artistic License 2.0
================================

