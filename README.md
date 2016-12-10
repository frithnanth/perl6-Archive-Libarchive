## Archive::Libarchive

Archive::Libarchive - OO interface to libarchive.

## Build Status

| Operating System  |   Build Status  | CI Provider |
| ----------------- | --------------- | ----------- |
| Linux             | [![Build Status](https://travis-ci.org/frithnanth/perl6-Archive-Libarchive.svg?branch=master)](https://travis-ci.org/frithnanth/perl6-Archive-Libarchive)  | Travis CI |

## Example

```Perl6
use v6;

use Archive::Libarchive;

sub MAIN(:$file! where { .IO.f // die "file '$file' not found" })
{
}

```

For more examples see the `example` directory.

## Description

Archive::Libarchive provides a procedural and a OO interface to libarchive using Archive::Libarchive::Raw.

As the Libarchive site (http://www.libarchive.org/) states, its implementation is able to:

* Read a variety of formats, including tar, pax, cpio, zip, xar, lha, ar, cab, mtree, rar, and ISO images.
* Write tar, pax, cpio, zip, xar, ar, ISO, mtree, and shar archives.
* Handle automatically archives compressed with gzip, bzip2, lzip, xz, lzma, or compress.

## Prerequisites

This module requires Archive::Libarchive::Raw Perl6 module and the libarchive library 
to be installed. Please follow the instructions below based on your platform:

### Debian Linux

```
sudo apt-get install libarchive13
```

The module looks for a library called libarchive.so, or whatever it finds in
the environment variable `PERL6_LIBARCHIVE_LIB` (provided that the library one
chooses uses the same API).

## Installation

To install it using Panda (a module management tool):

```
$ panda update
$ panda install Archive::Libarchive
```
To install it using zef (a module management tool):

```
$ zef update
$ zef install Archive::Libarchive
```

## Testing

To run the tests:

```
$ prove -e "perl6 -Ilib"
```

or

```
$ prove6
```

## Note

Archive::Libarchive::Raw and in turn this module rely on a C library which might not be present in one's
installation, so it's not a substitute for a pure Perl6 module.

This is a OO interface to the functions provided by the C library, accessible through the Archive::Libarchive::Raw
module.

## Author

Fernando Santagata

## Copyright and license

The Artistic License 2.0
