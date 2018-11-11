mediafileinfo.pl: Get parameters and dimension of media files.
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
mediafileinfo.pl is a self-contained Perl 5 script which detects file
format, media parameters (e.g. codec, dimensions (width and height)( of
media files (currently image only). It needs just Perl 5, no package
installation.

Supported image formats for dimension detection include JPEG, PNG, GIF,
PNM, BMP.

Please note that there is an alternative of mediafileinfo.pl: the Python
script mediafileinfo.py (http://github.com/pts/pymediafileinfo), which has
many more features: it supports many more media and other file formats,
including many popular video and audio formats; it supports getting the
video and audio codec; it supports getting the audio parameters.

Status: production ready for images. Please report
bugs on https://github.com/pts/plmediafileinfo/issues , your feedback is
very much appreciated.

System compatibility: Unix, Windows and any operating system supported by
Perl.

Advantages of mediafileinfo.pl:

* It's fast even though it's written in Perl, and some of
  the alternatives are written in C or C++.
* It has only a few dependencies: stock Perl 5; no package installation
  needed.

Disadvantages of mediafileinfo.pl:

* It supports only a few file formats (currently 5). For more (>80) file
  formats, see http://github.com/pts/pymediafileinfo .
* It isn't able to get metadata (such as author and EXIF tags).

Usage on Unix (don't type the leading $):

  $ curl -L -o mediafileinfo.pl https://github.com/pts/plmediafileinfo/raw/master/mediafileinfo.pl
  $ chmod 755 mediafileinfo.pl
  $ ./mediafileinfo.pl *.jpg
  (prints one line per file)

__END__
