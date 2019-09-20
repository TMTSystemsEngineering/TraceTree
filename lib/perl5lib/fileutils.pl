
# License Terms
# 
# Copyright (c) 2006,2007,2008,2009,2010,2011,2012,2013, California 
# Institute of Technology ("Caltech").  U.S. Government sponsorship 
# acknowledged. 
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are 
# met: 
# 
# 
# *   Redistributions of source code must retain the above copyright 
#     notice, this list of conditions and the following disclaimer.
# 
# *   Redistributions in binary form must reproduce the above copyright 
#     notice, this list of conditions and the following disclaimer in the 
#     documentation and/or other materials provided with the distribution.
# 
# *   Neither the name of Caltech nor its operating division, the Jet 
#     Propulsion Laboratory, nor the names of its contributors may be used 
#     to endorse or promote products derived from this software without 
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR 
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT 
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY 
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
require "miscutils.pl" ;

#
#! getfilelist( [ dirname [, patternregexp] ] )

#  returns a list of all files in directory named dirname, except '.' 
#  and '..'.  If dirname is not supplied, '.' is assumed.  If 
#  patternregexp is supplied, getfilelist will also filter out filenames 
#  not matching patternregexp. 

sub getfilelist 
{
  my ($dir, $pat) = @_ ;
  local (*DIR) ;
  my (@list) ;

  $dir = '.' if !$dir ;

  if (opendir (DIR, $dir))
  {
    if ($pat)
    {
      while ($fname = readdir (DIR))
      {
	push @list, $fname 
	  if ($fname !~ /^\.{1,2}$/ and $fname =~ /$pat/ ) ;
      }
    }
    else
    {
      @list = grep !/^\.{1,2}$/, readdir (DIR) ;
    }
      
    closedir (DIR) ;
  }
  else
  {
    warn "Couldn't open $dir: $!" ;
  }
  return @list ;
}

sub getdirlist
{
  my ($dir, $pat) = @_ ;
  local (*DIR) ;
  my (@tmplist) ;
  my (@list) ;
  my ($fname, $relpath) ;

  $dir = '.' if !$dir ;

  if (opendir (DIR, $dir))
  {
    if ($pat)
    {
      while ($fname = readdir (DIR))
      {
	push @tmplist, $fname 
	  if ($fname !~ /^\.{1,2}$/ and $fname =~ /$pat/ ) ;
      }
    }
    else
    {
      @tmplist = grep !/^\.{1,2}$/, readdir (DIR) ;
    }
    closedir (DIR) ;
    ####################################################################
    # How did this work/not work so long? It doesn't work unless $dir  #
    # is "."                                                           #
    ####################################################################
    # print STDERR "tmplist = @tmplist\n" ;
    # @list = grep -d, @tmplist ;
    # print STDERR "list = @list\n" ;
    foreach $fname (@tmplist)
    {
      $relpath = $dir . "/" . $fname ;
      push @list, $fname if -d $relpath ;
    }
      
  }
  else
  {
    warn "Couldn't open $dir: $!" ;
  }
  return @list ;
}

# getfilelistrecursive is like getfilelist except that it recursively 
# goes down from $dir to find all plain files matching $pat (if $pat is 
# given).  All directories are searched, regardless of whether $pat is 
# given.  Unless $dir eq ".", the directory name is prepended to the 
# filename.  Thus you end up with relative pathnames beginning with the 
# directory specified (or the current directory if "." was specified.) 
#
# All of the arguments are optional.  The third argument, if specified, 
# is a reference to an accumulating list of files.  This is used in the 
# calls to itself that getfilelistrecursive makes, but one could specify 
# it in the first call if desired. 

sub getfilelistrecursive
{
  my ($accumlist, $accumlistspecified, $file, 
      @thisdirsdirs, @thisdirsfiles, @thisdirsplains) ;

  # IF the last argument is a reference, it's a reference to the 
  # accumulating list of files, so pop it off for later use
  $accumlist = pop if ref($_[$#_]) ;
  my ($dir, $ppat, $dpat) = @_ ;

  $dir = '.' if !$dir ;
  $ppat = '' if !$ppat ;  # we do this so the recursive call makes sense
  $dpat = '' if !$dpat ;  # we do this so the recursive call makes sense

  # Don't use the pattern yet - you'll miss most of the directories!
  #  But we don't want links at all

  @thisdirsfiles = getfilelist($dir) ;

  foreach $file (@thisdirsfiles) 
  {
    next if -l "$dir/$file";
    push @thisdirsplains, $file if -f _ ;
    push @thisdirsdirs, $file if -d _ ;
  }
  @thisdirsplains = grep (/$ppat/, @thisdirsplains) if $ppat ;
  @thisdirsplains = map ("$dir/$_", @thisdirsplains) if $dir ne '.' ;

  @thisdirsdirs = grep (/$dpat/, @thisdirsdirs) if $dpat ;
  @thisdirsdirs   = map ("$dir/$_", @thisdirsdirs  ) if $dir ne '.' ;

  if ($accumlist)
  {
    $accumlistspecified++ ;
    push (@$accumlist, @thisdirsplains) ;
  }
  else
  {
    # if we haven't already started, we start now.
    $accumlist = \@thisdirsplains ;
  }

  foreach $dir (@thisdirsdirs)
  {
    getfilelistrecursive ($dir, $ppat, $dpat, $accumlist) ;
  }

  # We should return @$accumlist only if $accumlist was not specified 
  # in the argument list for this call.  Otherwise return nothing.

  #  Following was : if (@$accumlistspecified)  that should be wrong
  if ($accumlistspecified)
  {
    return 0 ;
  }
  else
  {
    return @$accumlist ;
  }
}

# getdirlistrecursive is like getfilelistrecursive except that it 
# only gets directories.  Therefore it has no ppat argument.

sub getdirlistrecursive
{
  my ($accumlist, $accumlistspecified, $file, 
      @thisdirsdirs, @thisdirsfiles, @thisdirslistdirs) ;
  $accumlist = pop if ref($_[$#_]) ;
  my ($dir, $dpat) = @_ ;

  $dir = '.' if !$dir ;

  # Don't use the pattern yet - you'll miss most of the directories!
  #  But we don't want links at all

  @thisdirsfiles = getfilelist($dir) ;


  foreach $file (@thisdirsfiles) 
  {
    next if -l "$dir/$file";   # skip links
    push @thisdirsdirs, $file if -d _ ;
  }

  @thisdirsdirs   = map ("$dir/$_", @thisdirsdirs  ) if $dir ne '.' ;

  if ($accumlist)
  {
    $accumlistspecified++ ;
    push (@$accumlist, @thisdirsdirs) ;
  }
  else
  {
    # if we haven't already started, we start now.
    $accumlist = \@thisdirsdirs ;
  }

  foreach $dir (@thisdirsdirs)
  {
    getdirlistrecursive ($dir, $dpat, $accumlist) ;
  }

  # We should return @$accumlist only if $accumlist was not specified 
  # in the argument list for this call.  Otherwise return nothing.

  if ($accumlistspecified)
  {
    return 0 ;
  }
  else
  {
    return grep (/$dpat/, @$accumlist) if $dpat ;
    return @$accumlist ;   # else...
  }
}

#  SORTING FILES BY AGE (youngest listed first in result):
# Usage:
#  @agelist = sort byage @filelist ; 
# We could also use a routine that uses an array reference for each of the
# two files, so that we don't keep looking up the age...

# Solution for large array of file names is to pass in the entire array 
# (by reference) to a sorting function, which would then get the ages of 
# each file, once, then sort it using something like this routine. 

sub byage 
{
  local ($aage, $bage) ;
  $aage = -M $a ;
  $bage = -M $b ;

  return $aage <=> $bage ;
}

sub bysize 
{
  local ($asize, $bsize) ;
  $asize = -M $a ;
  $bsize = -M $b ;

  return $asize <=> $bsize ;
}

## Currently requires an extension directly after the number.  Also ignores
# a number that is not preceded by a non-alphanumeric
sub sortfilesbynumber
{
  local (@list) = @_ ;
  local (@pairs) ;
  local (@pair) ;
  local ($n) ;
  local ($i) ;

  foreach (@list)
  {
    if (/\W+(\d+)\.\w+$/) { $n = $1 ; } else { $n = 0 ; }
    push @pairs, [ $_ , $n ] ;
  }
  @pairs = sort cmpbypairnumeric @pairs ;
  foreach (@pairs)
  {
    $list[$i++] = $$_[0] ;
  }
  return @list ;
}

sub sortfilesbyage
{
  local (@list) = @_ ;
  local (@pairs) ;
  local (@pair) ;
  local ($i) ;

  foreach (@list)
  {
    push @pairs, [ $_ , -M $_ ] ;
  }
  @pairs = sort cmpbypairnumeric @pairs ;
  foreach (@pairs)
  {
    $list[$i++] = $$_[0] ;
  }
  return @list ;
}

sub sortfilesbylatestaccess
{
  local (@list) = @_ ;
  local (@pairs) ;
  local (@pair) ;
  local ($i) ;

  foreach (@list)
  {
    push @pairs, [ $_ , -A $_ ] ;
  }
  @pairs = sort cmpbypairnumeric @pairs ;
  foreach (@pairs)
  {
    $list[$i++] = $$_[0] ;
  }
  return @list ;
}

sub sortfilesbysize
{
  local (@list) = @_ ;
  local (@pairs) ;
  local (@pair) ;
  local ($i) ;

  foreach (@list)
  {
    push @pairs, [ $_ , -s $_ ] ;
  }
  @pairs = sort cmpbypairnumeric @pairs ;
  foreach (@pairs)
  {
    $list[$i++] = $$_[0] ;
  }
  return @list ;
}

########################################################################
# split the lines of a scalar containing, presumbably but not          #
# necessarily, all the lines of a file into a list without regard to   #
# line-ending: dos, mac, unix.  We assume that there is nothing        #
# pathological about this file - all line endings are the same.        #
########################################################################
sub splitfilelines # ($data)
{
  my ($data) = @_ ;
  my (@result) ;
  ######################################################################
  # Tried to use split here, but multiple blank lines fooled it.       #
  ######################################################################
  $data =~ s/\r\n/\n/gm ;   # dos to unix
  $data =~ s/\r/\n/gm ;     # mac to unix
  while ($data ne "")
  {
    if ($data =~ /(.*?)\n/mo)
    {
      push @result, $1 ;
      $data = $' ;
    }
    else
    {
      push @result, $data ;
      $data = "" ;
    }
  }
  return @result ;
}

########################################################################
# DOES NOT TRAVERSE SYMBOLIC LINKS                                     #
########################################################################
sub getdirlistrecursivesimple # ($dirname, [$ref to don't go below hash])
{
  my ($dir, $dontGoBelowHashref) = @_ ;
  local (*DIR) ;
  my (@result, @list) ;
  my ($fname) ;
  $dir = '.' if !$dir ;
  $dir =~ s/\/$// ;  # don't want trailing slash
  if (opendir (DIR, $dir))
  {
    @list = grep !/^\.{1,2}$/, readdir (DIR) ;      
    closedir (DIR) ;
    @list = map ("$dir/$_", @list ) if $dir ne '.' ;
    foreach $fname (@list)
    {
      if (-d $fname and ! -l $fname) 
      { 
        push @result, $fname ;
        if (!defined $dontGoBelowHashref 
          or !exists($dontGoBelowHashref->{$fname}) )
        {
          push @result, getdirlistrecursivesimple ($fname, $dontGoBelowHashref) ; 
        }
      }
    }
  }
  else
  {
    warn "getdirlistrecursivesimple: couldn't open $dir: $!\n" ;
  }  
  return @result ;
}

sub getinode
{
  my ($filename) = @_ ;

  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
      $atime,$mtime,$ctime,$blksize,$blocks)
	    = stat($filename);
  return $ino ;
}

# won't check inodes
sub copyfilenocheck
{
  my ($srcfile, $dstfile, $nblocks) = @_ ;
  my ($size, $result, $oresult) ;
  local (*I, *O) ;

  if (! defined $nblocks) { $nblocks = 4 ; }

  $size = -s $srcfile ;
  open I, $srcfile or die "copyfile: couldn't open $srcfile for reading: $!\n" ;
  open O, "> $dstfile" or die "copyfile: couldn't open $dstfile for writing: $!\n" ;

  my ($totalbytes, $inbuff, $errno);

  $totalbytes = 0 ;
  while (1)
  {
    $result = sysread I, $inbuff, 8192*$nblocks ;
    last if $result == 0 ;  # eof
    if (!defined $result) # error
    {
      $errno = $! ;
      $! = $errno ;
      warn "read error on $srcfile: $!\n" ;
      close I ;
      close O ;
      unlink $dstfile or die "Couldn't unlink $dstfile: $!\n" ;
      exit $errno ;
    }
    # otherwise read was good, though maybe not of length 8192
    $oresult = syswrite O, $inbuff, $result ;
    if (!defined $oresult) # error
    {
      $errno = $! ;
      $! = $errno ;
      warn "write error on $dstfile: $!\n" ;
      close I ;
      close O ;
      unlink $dstfile or die "Couldn't unlink $dstfile: $!\n" ;
      exit $errno ;
    }
    $totalbytes += $oresult ;
  }
  close I ; 
  close O ;
  return $totalbytes ;
}

sub copyfile
{
  my ($srcfile, $dstfile, $nblocks) = @_ ;
  my ($sinode, $dinode) ;
  my ($size, $result, $oresult) ;
  local (*I, *O) ;

  if (! defined $nblocks) { $nblocks = 4 ; }

  $sinode = getinode ($srcfile) ;
  $dinode = getinode ($dstfile) ;
  if (defined $dinode and defined $sinode and $dinode == $sinode)
  {
    ##################################################################
    # not complete check, BOZO.  Could be identical inodes but on    #
    # different volumes.                                             #
    ##################################################################
    die "copyfile: $srcfile and $dstfile are identical (not copied).\n" ;
  }
  # let other errors be handled by open function 

  $size = -s $srcfile ;
  open I, $srcfile or die "copyfile: couldn't open $srcfile for reading: $!\n" ;
  open O, "> $dstfile" or die "copyfile: couldn't open $dstfile for writing: $!\n" ;

  my ($totalbytes, $inbuff, $errno);

  $totalbytes = 0 ;
  while (1)
  {
    $result = sysread I, $inbuff, 8192*$nblocks ;
    last if $result == 0 ;  # eof
    if (!defined $result) # error
    {
      $errno = $! ;
      $! = $errno ;
      warn "read error on $srcfile: $!\n" ;
      close I ;
      close O ;
      unlink $dstfile or die "Couldn't unlink $dstfile: $!\n" ;
      exit $errno ;
    }
    # otherwise read was good, though maybe not of length 8192
    $oresult = syswrite O, $inbuff, $result ;
    if (!defined $oresult) # error
    {
      $errno = $! ;
      $! = $errno ;
      warn "write error on $dstfile: $!\n" ;
      close I ;
      close O ;
      unlink $dstfile or die "Couldn't unlink $dstfile: $!\n" ;
      exit $errno ;
    }
    $totalbytes += $oresult ;
  }
  close I ; 
  close O ;
  return $totalbytes ;
}

########################################################################
# Returns zero if files are different, one if the same.  Checks sizes  #
# first in an effort to avoid opening the files.  Further              #
# optimization would be to compare blocks the same size as disk        #
# blocks, rather than scarfing up entire file, but we don't do that.   #
########################################################################
sub comparefiles # ($fname1, $fname2)
{
  my ($fname1, $fname2) = @_ ;
  return 0 if (( ! -e $fname1) or (! -e $fname2)) ;
  return 0 if (-s $fname1) != (-s $fname2) ;
  my ($contents1, $contents2) ;
  open CC1, "$fname1" or die "Couldn't open $fname1 for reading: $!\n" ;
  $/ = undef ;
  $contents1 = <CC1> ; #  scarf it all up
  close CC1 ;
  open CC2, "$fname2" or die "Couldn't open $fname2 for reading: $!\n" ;
  $/ = undef ;
  $contents2 = <CC2> ; #  scarf it all up
  close CC2 ;
# print "OLD:\n$contents1\n==========\n" ;
# print "NEW:\n$contents2\n==========\n" ;
  return $contents1 eq $contents2 ;
}
# Returns 
#   0 for files identical, 
#   1 for files not identical, 
#   -1 for error, or same name
#   -2 for same inode (i.e. hard linked files), 
#   -3 for zero-length (therefor identical, but what does that mean?)
#
# Reason we return 1 for "not identical" is because likely calling 
# function for "is equal" is to do something drastic like delete the 
# file. But an error returns -1, which with a naive test looks like 
# "true".  So if you delete something if the function call returns true, 
# you'd be deleting something based on an error. 
#
# possible errors:
#    argument error
#    either file not a simple file
#    either file doesn't exist
#    read error of any sort
sub quickfilecomparenotequal # ($filename1, $filename2)
{
  my ($f1, $f2) = @_ ;
  local (*F1, *F2) ;
  my ($dev1,$ino1,$mode1,$nlink1,$uid1,$gid1,$rdev1,$size1,
                          $atime1,$mtime1,$ctime1,$blksize1,$blocks1) ;
  my ($dev2,$ino2,$mode2,$nlink2,$uid2,$gid2,$rdev2,$size2,
                          $atime2,$mtime2,$ctime2,$blksize2,$blocks2) ;
  my ($bsize) = 4096 ;  # we'll ignore the blksize returned by stat, at 
                        # least for now 

  return -1 if ! defined $f1 ;
  return -1 if ! defined $f2 ;
  return -1 if $f1 eq $f2 ;
  # should check inodes equal
#   ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
#                           $atime,$mtime,$ctime,$blksize,$blocks)
#			                           = stat($filename);
  return -1 if ! -f $f1 ;
  # should check inodes equal
#   ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
  ($dev1,$ino1,$mode1,$nlink1,$uid1,$gid1,$rdev1,$size1,
                          $atime1,$mtime1,$ctime1,$blksize1,$blocks1)
		                           = stat(_);
  return -1 if ! -f $f2 ;
  ($dev2,$ino2,$mode2,$nlink2,$uid2,$gid2,$rdev2,$size2,
                          $atime2,$mtime2,$ctime2,$blksize2,$blocks2)
		                           = stat(_);
  return 1 if $size1 != $size2 ; # file sizes not equal implies not identical
  return -2 if $ino1 == $ino2 ; # if the inodes are the same, they are 
                                # not only identical but also exactly 
                                # the same file, and any program 
                                # deleting identical files may not wish 
                                # to delete hard links 
  return -3 if $size1 == 0 ;  # both files are zero length implies 
                              # identical, but we should flag this 
                              # because often zero-length files are 
                              # semantically not identical 

  open F1, $f1 or return -1 ;
  open F2, $f2 or return -1 ;

  my ($buf1, $buf2) ;
  my ($bstart, $bytestoread, $bytesread) ;
  my ($founddiff) = 0 ;

  for ($bstart = 0 ; $bstart < $size1 ; $bstart += $bsize)
  {
    $bytestoread = $size1 - $bstart ;
    $bytestoread = $bsize if $bytestoread > $bsize ;

    $bytesread = sysread F1, $buf1, $bytestoread ;
    if ((!defined $bytesread) || ($bytesread == 0) || ($bytesread < $bytestoread))
    {
      close F1 ;
      close F2 ;
      return -1 ;
    }
    $bytesread = sysread F2, $buf2, $bytestoread ;
    if ((!defined $bytesread) || ($bytesread == 0) || ($bytesread < $bytestoread))
    {
      close F1 ;
      close F2 ;
      return -1 ;
    }
    # We got this far, we have good data
    $founddiff = 1  if $buf1 ne $buf2 ;
    last if $founddiff ;    # need go no further if we found a difference
  }
  close F1 ;
  close F2 ;
  return $founddiff ;    # $founddiff returns exactly what we want

}
  


1;
