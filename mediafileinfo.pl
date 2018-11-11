#! /bin/sh
eval '(exit $?0)' && eval 'PERL_BADLANG=x;PATH="$PATH:.";export PERL_BADLANG\
;exec perl -w -x -S -- "$0" ${1+"$@"};#'if 0;eval 'setenv PERL_BADLANG x\
;setenv PATH "$PATH":.;exec perl -w -x -S -- "$0" $argv:q;#'.q
#!perl -w
+push@INC,'.';$0=~/(.*)/s;do(index($1,"/")<0?"./$1":$1);die$@if$@__END__+if 0
;#Don't touch/remove lines 1--7: http://www.inf.bme.hu/~pts/Magic.Perl.Header
#
# mediafileinfo.pl: Get codecs and dimension of media files.
# by pts@fazekas.hu at Sun Nov 11 11:34:11 CET 2018
#

use integer;
use strict;

#** @param $_[0] Filehandle.
#** @param $_[1] Filename, only for reporting errors.
#** @return ($format, $codec, $width, $height) tuple. Only $codec can be
#**     undef. die(...) is used if cannot be determined.
sub get_media_info($$) {
  my($fh, $fn) = @_;
  my $read = sub {
    my $data;
    die "error: read: $fn: $!\n" if !defined(read($fh, $data, $_[0]));
    $data;
  };
  my $read_all = sub {
    my $data;
    die "error: read: $fn: $!\n" if !defined(read($fh, $data, $_[0]));
    die "error: short read: $fn\n" if length($data) != $_[0];
    $data;
  };
  my($format, $codec, $width, $height);
  my $header = $read->(4);
  if ($header eq "\211PNG") {  # PNG.
    ($format, $codec) = ("png", "flate");
    $header .= $read_all->(7);
    die "error: bad PNG header: $fn\n" if $header ne "\211PNG\r\n\032\n\0\0\0";
    my($c, $ihdr);
    ($c, $ihdr, $width, $height) = unpack("ca4NN", $read_all->(13));
    die "error: bad PNG IHDR header: $fn\n" if $ihdr ne "IHDR";
  } elsif ($header eq "GIF8") {  # GIF.
    ($format, $codec) = ("gif", "lzw");
    $header .= $read_all->(6);
    my($subformat);
    ($subformat, $width, $height) = unpack("a6vv", $header);
    die "error: bad GIF header: $fn\n" if
        $subformat ne "GIF87a" and $subformat ne "GIF89a";
  } elsif ($header =~ m@\AP[1-6][#\s]@) {  # PNM.
    $header .= $read->(508);
    die "error: bad PNM header: $fn\n" if
        $header !~ m@\AP[1-6](?:#[^\n]*\n|\s)+(\d+)(?:#[^\n]*\n|\s)+(\d+)[#\s]@;
    ($width, $height) = ($1 + 0, $2 + 0);
    $format = ["ppm", "pbm", "pgm"]->[vec($header, 1, 8) % 3];
    $codec = ["rawascii", "raw"]->[vec($header, 1, 8) > 0x33];
  } elsif ($header =~ m@\ABM@) {  # BMP.
    ($format, $codec) = ("bmp", "undef");
    $header .= $read_all->(22);
    my $b = vec($header, 14, 8);
    die "error: bad BMP header: $fn\n" if
      substr($header, 6, 4) ne "\0\0\0\0" or
      substr($header, 15, 3) ne "\0\0\0";
    if ($b == 12 or $b == 26) {  # convert ... bmp2:...
      ($width, $height) = unpack("x18vv", $header);
    } elsif ($b == 40 or $b == 124) {  # convert ... bmp3:...
      ($width, $height) = unpack("x18VV", $header);
    } else {
      die "error: unknown BMP subformat $b: $fn\n";
    }
  } elsif ($header =~ m@\A\xff\xd8\xff@) {  # JPEG.
    ($format, $codec) = ("jpeg", "jpeg");
    # Implementation based on pts-qiv
    #
    # A typical JPEG file has markers in these order:
    #   d8 e0_JFIF e1 e1 e2 db db fe fe c0 c4 c4 c4 c4 da d9.
    #   The first fe marker (COM, comment) was near offset 30000.
    # A typical JPEG file after filtering through jpegtran:
    #   d8 e0_JFIF fe fe db db c0 c4 c4 c4 c4 da d9.
    #   The first fe marker (COM, comment) was at offset 20.
    my $m = vec($header, 3, 8);
    while (1) {
      $m = ord($read_all->(1)) while $m == 0xff; # Padding.
      if ($m == 0xd8 or $m == 0xd9 or $m == 0xda) {
        # 0xd8: SOI unexpected.
        # 0xd9: EOI unexpected before SOF.
        # 0xda: SOS unexpected before SOF.
        die sprintf("error: unexpected JPEG marker 0x%02x: %s", $m, $fn);
      }
      my $ss = unpack("n", $read_all->(2));
      die "error: JPEG segment too short: $fn\n" if $ss < 2;
      $ss -= 2;
      if ($m >= 0xc0 and $m <= 0xcf and
          $m != 0xc4 and $m != 0xc8 and $m != 0xcc) {  # SOF0 ... SOF15.
        die "error: JPEG SOF segment too short: $fn\n" if $ss < 5;
        ($height, $width) = unpack("xnn", $read_all->(5));
        last;
      }
      $read_all->($ss);
      $m = $read_all->(2); # Read next marker to m.
      die "error: JPEG marker expected: $fn\n" if substr($m, 0, 1) ne "\xff";
      $m = vec($m, 1, 8);
    }
  } else {
    die "error: unknown file format: $fn\n"
  }
  ($format, $codec, $width, $height)
}

{ my $fh = select(STDOUT); $| = 1; select($fh); }
for my $fn (@ARGV) {
  my($fh, @media_info);
  if (!open($fh, "<", $fn)) {
    print STDERR "error: missing file: $fn: $!\n";
    next;
  }
  eval { @media_info = get_media_info($fh, $fn); };
  my $error = "$@";
  my $hdr_done_at = tell($fh);
  if (!seek($fh, 0, 2)) {
    my $msg = "$!";
    die if !close($fh);
    print STDERR "error: error seeking in file: $fn: $msg\n";
    next;
  }
  my $size = tell($fh);
  die if !close($fh);
  if ($error) {
    print "format=? hdr_done_at=$hdr_done_at size=$size f=$fn\n";
    $error =~ s@\Aerror: (unknown file format: )@warning: $1@;
    print STDERR $error;
  } else {
    my($format, $codec, $width, $height) = @media_info;
    my $codec_item = defined($codec) ? "codec=$codec " : "";
    print "format=$format ${codec_item}hdr_done_at=$hdr_done_at " .
          "height=$height size=$size width=$width f=$fn\n";
  }
}
