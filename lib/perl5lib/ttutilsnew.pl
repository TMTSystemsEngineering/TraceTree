
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
use Digest::MD5 ;

require "fileutils.pl" ;

$nbsp = "&nbsp;" ;
$nbsp2 = "$nbsp$nbsp" ;
$nbsp4 = "$nbsp2$nbsp2" ;
$nbsp6 = "$nbsp4$nbsp2" ;

@extsOfSourceFiles = ("xml", "attr", "png") ;
# WAS @extsOfSourceFiles = ("xml", "lnks", "attr", "png") ;
@extsOfIntermediateFiles = ("dot", "objtxt", "map") ;
@extsOfDestinationFiles = ("html", "gif") ;
@listForGetUsualObjectFiles = (@extsOfSourceFiles, @extsOfIntermediateFiles, @extsOfDestinationFiles) ;


sub htmlheader # ($title [, $styleroot])
{
  my ($title, $styleroot) = @_ ;
  my ($hh) =<<EOHH ;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
  <head><title>TITLE</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
    <link href="tracetreestyles.css" rel="stylesheet" type="text/css">
  </head>
  <body>
EOHH
  $hh =~ s/TITLE/$title/ ;
  $hh =~ s/tracetreestyles/$styleroot\/tracetreestyles/ if defined $styleroot ; 
  return $hh ;
}

########################################################################
# Convert a bunch of text lines to html.  Add <br>, <p>, and <table>   #
# type tags.  Use a table in case there are tabs found in the text     #
# (other than initial paragraph tabs, hopefully).  If there are tabs,  #
# entire html output is a table, with tabless paragraphs spanning all  #
# of the columsn of the table.                                         #
########################################################################
sub txttohtml # (@textlines)
{
  my (@textlines) = @_ ;
  my (@fields) ;
  my ($ifield, $nfields) ;
  my ($maxntabs, $ntabs, $maxnfields, $result) ;
  my ($line, $iline) ;

  $maxntabs = 0 ;
  foreach $line (@textlines)
  {
    $ntabs = $line =~ /\t/ ;
    # if it's just a leading tab we'll take care of it later
    $ntabs = 0 if $ntabs == 1 and $line =~ /^\t/ ;
    $maxntabs = $ntabs > $maxntabs ? $ntabs : $maxntabs ;
  }

  if ($maxntabs == 0)
  {
    # just make it a paragraph with added <br>s
    $result = "<p>\n" ;
    for ($iline = 0 ; $iline < scalar (@textlines) ; $iline++)
    {
      $line = $textlines[$iline] ;
      # take care of initial tab
      $line =~ s/^\t/$nbsp6/ ; 
      $result .= "$line<br>\n" ;
    }
    $result .= "</p>\n" ;
  }
  else
  {
    # now we have to do the table thing.
    # instead of lines with <br>s, we use table rows and colspans
    $result = "<table border=\"0\" cellpadding=\"3\">\n" ;
    $maxnfields = $maxntabs+1 ;
    for ($iline = 0 ; $iline < scalar (@textlines) ; $iline++)
    {
      $line = $textlines[$iline] ;
      @fields = split /\t/, $line;
      $result .= "<tr>" ;
      $nfields = scalar (@fields) ;
      if ($nfields == 0) 
      {
	$result .= "<td></td>" ;
      }
      elsif ($nfields == 1)
      {
	$result .= "<td colspan=\"$maxnfields\">$line</td>" ;
      }
      else
      {
	$result .= "\n" ;
	for ($ifield = 0 ; $ifield < $nfields ; $ifield++)
	{
	  $result .= "  <td>$fields[$ifield]</td>\n" ;
	}
      }
      $result .= "</tr>\n" ;
    }
    $result .= "</table>\n" ;
  }
  return $result ;
}
  
########################################################################
# about the same as txttohtml but without paragraph marks              #
########################################################################
sub txttohtmlnopar # (@textlines)
{
  my (@textlines) = @_ ;
  my (@fields) ;
  my ($ifield, $nfields) ;
  my ($maxntabs, $ntabs, $maxnfields, $result) ;
  my ($line, $iline) ;

  $maxntabs = 0 ;
  foreach $line (@textlines)
  {
    $ntabs = $line =~ /\t/ ;
    # if it's just a leading tab we'll take care of it later
    $ntabs = 0 if $ntabs == 1 and $line =~ /^\t/ ;
    $maxntabs = $ntabs > $maxntabs ? $ntabs : $maxntabs ;
  }

  if ($maxntabs == 0)
  {
    # just make it a paragraph with added <br>s
    $result = "" ;
    for ($iline = 0 ; $iline < scalar (@textlines) ; $iline++)
    {
      $line = $textlines[$iline] ;
      # take care of initial tab
      $line =~ s/^\t/$nbsp6/ ;
      $result .= $line ;
      $result .= "<br>" if $iline < scalar (@textlines) - 1 ;
      $result .= "\n" ;
    }
  }
  else
  {
    # now we have to do the table thing.
    # instead of lines with <br>s, we use table rows and colspans
    $result = "<table border=\"0\" cellpadding=\"3\">\n" ;
    $maxnfields = $maxntabs+1 ;
    for ($iline = 0 ; $iline < scalar (@textlines) ; $iline++)
    {
      $line = $textlines[$iline] ;
      @fields = split /\t/, $line;
      $result .= "<tr>" ;
      $nfields = scalar (@fields) ;
      if ($nfields == 0) 
      {
	$result .= "<td></td>" ;
      }
      elsif ($nfields == 1)
      {
	$result .= "<td colspan=\"$maxnfields\">$line</td>" ;
      }
      else
      {
	$result .= "\n" ;
	for ($ifield = 0 ; $ifield < $nfields ; $ifield++)
	{
	  $result .= "  <td>$fields[$ifield]</td>\n" ;
	}
      }
      $result .= "</tr>\n" ;
    }
    $result .= "</table>\n" ;
  }
  return $result ;
}

# this is way too simplistic.  It stomps all over legitimate markup.
sub htmlquotampgtlt # (@textlines)
{
  my (@textlines) = @_ ;
  foreach $line (@textlines)
  {
    $line =~ s/\&/&amp;/g ;  # Make sure this is first!
    $line =~ s/"/&quot;/g ;
    $line =~ s/</&lt;/g ;
    $line =~ s/>/&gt;/g ;
  }
  return @textlines ;
}

########################################################################
# Given a relative path to an object, such as found in the filelist    #
# files, find all the usual files - source, intermediate,              #
# distribution, but not the tmp and backup files. Does not find        #
# module/directory level files such as sequence.txt                    #
########################################################################

sub getusualobjectfiles
{
  my ($relobjpath) = @_ ;
  my ($ext, $fname, @result) ;
  @result = () ;
  # should really combine normal with png somehow...
  foreach $ext (@listForGetUsualObjectFiles) 
  {
    $fname = $relobjpath . ".$ext" ;
    push @result, $fname if -e $fname ;
  }
  # now for special case.  shit.
  if ($relobjpath =~ /^(.*?)\/(\d+)$/)
  {
    my $reldirpath = $1 ;
    my $nodenumber = $2 ;
    my (@pnglist) = getfilelist ($reldirpath, "^$nodenumber-\\d+\.png\$") ;
    if (@pnglist)
    {
      @pnglist = map { s/^/$reldirpath\// ; $_ ; } @pnglist ;
      push @result, @pnglist ;
    }
  }

  return @result ;
}

sub getnodelist 
{
  my ($pname) = @_ ;
  my ($nodefilename) = "LogsAndData/$pname.nodelist" ;
  my (@result) ;
  local *NODES ;
  if (! -e $nodefilename)
  {
    warn "No node list file found - $nodefilename\n" ;
  }
  else
  {
    open NODES, "$nodefilename" 
        or warn "getnodelist: couldn't open $nodefilename for reading: $!\n" ;
    @result = (<NODES>) ;
    chomp @result ;
    close NODES ;
  }
  return @result ;
}

sub getalldirlist
{
  my ($pname) = @_ ;
  my ($alldirfilename) = "LogsAndData/$pname.alldirlist" ;
  my (@result) ;
  local *ALLDIRS ;
  if (! -e $alldirfilename)
  {
    warn "No alldir list file found - $alldirfilename\n" ;
  }
  else
  {
    open ALLDIRS, "$alldirfilename" 
        or warn "getalldirlist: couldn't open $alldirfilename for reading: $!\n" ;
    @result = (<ALLDIRS>) ;
    chomp @result ;
    close ALLDIRS ;
  }
  return @result ;
}

sub getemptydirlist
{
  my ($pname) = @_ ;
  my ($emptydirfilename) = "LogsAndData/$pname.emptylist" ;
  my (@result) ;
  local *EMPTY ;
  if (! -e $emptydirfilename)
  {
    warn "No empty dir list file found - $emptydirfilename\n" ;
  }
  else
  {
    open EMPTY, "$emptydirfilename" 
        or warn "getemtpydirlist: couldn't open $emptydirfilename for reading: $!\n" ;
    @result = (<EMPTY>) ;
    chomp @result ;
    close EMPTY ;
  }
  return @result ;
}

sub getseqdirlist
{
  my ($pname) = @_ ;
  my ($seqdirfilename) = "LogsAndData/$pname.seqdirlist" ;
  my (@result) ;
  local *SEQDIRS ;
  if (! -e $seqdirfilename)
  {
    warn "No seqdir list file found - $seqdirfilename\n" ;
  }
  else
  {
    open SEQDIRS, "$seqdirfilename" 
        or warn "getseqdirlist: couldn't open $seqdirfilename for reading: $!\n" ;
    @result = (<SEQDIRS>) ;
    chomp @result ;
    close SEQDIRS ;
  }
  return @result ;
}


########################################################################
# targetNeedsUpdating returns true if the sourcefile has been          #
# modified more recently than the targetfile, meaning that the         #
# targetfile needs to be updated.  Also returns true if either         #
# sourcefile or targetfile don't exist.                                #
########################################################################
sub targetNeedsUpdating # (sourcefile, targetfile)
{
  my ($sourcefile, $targetfile) = @_ ;
  return 1 if ((! -e $sourcefile) or (! -e $targetfile)) ;
  # remember -M returns age
  return 1 if (-M $sourcefile) < (-M $targetfile) ;
  return 0 ;
}
  

########################################################################
# targetNeedsUpdatingPlural returns true if any of the the             #
# sourcefiles have been modified more recently than the targetfile,    #
# meaning that the targetfile needs to be updated.  Also returns true  #
# if any sourcefile or the targetfile doesn't exist.                   #
########################################################################
sub targetNeedsUpdatingPlural # (@sourcefile, $targetfile)
{
  my (@filelist) = @_ ;
  my (@sourcefiles, $targetfile, $sourcefile, $tage, $sage) ;
  @sourcefiles = @filelist[0 .. ($#filelist - 1)] ;
  $targetfile = $filelist[$#filelist] ;
  return 1 if ! -e $targetfile ;
  $tage = -M _ ;
  foreach $sourcefile (@sourcefiles) 
  {
    return 1 if ! -e $sourcefile ;
    $sage = -M _ ;
    # remember -M returns age
    return 1 if $sage < $tage ;
  }
  return 0 ;
}

########################################################################
# parseattributedata take multi-line data straight out of a            #
# ttr-specific attribute file and parses it fairly stupidly into an    #
# array of alternating attribute names and values.  This really        #
# sucks.  Ought do something more sophisticated.  But it works.        #
########################################################################
sub parseattributedata # ($data) - multi-line $data
{
  my ($data) = @_ ;
  my ($contents, $attrdata, $attrname, $attrvalue) ;
  my (@result) ;
  die "Couldn't find attributes data\n" 
  if $data !~ /<attributes>(.*)<\/attributes>/s ;
  $contents = $1 ;

  while ($contents =~ /<attr>(.*?)<\/attr>/s)
  {
    $attrdata = $1 ;
    $contents = $' ;
    die "Couldn't find an attrname in -->$attrdata<--\n" 
	if $attrdata !~ /<attrname>(.*)<\/attrname>/s ;
    $attrname = $1 ;
    die "Couldn't find an attrvalue in -->$attrdata<--\n" 
    if $attrdata !~ /<attrvalue>(.*)<\/attrvalue>/s ;
    $attrvalue = $1 ;
    push @result, $attrname, $attrvalue ;
  }
  return @result ;
}

########################################################################
# parseattributefile is an attempt to be more sophisticated than       #
# parseattribute data.  It starts with the ttr-specific attribute      #
# file named in the argument and returns a hash.  Returns undefined    #
# if anything goes wrong.                                              #
########################################################################

sub parseattributefile # ($filename)
{
  my ($filename) = @_ ;
  local (*ATTR) ;        # oughta be OK if parseattributefile not called 
                         # recursively 
  my ($filedata, $contents, $attrdata, $attrname, $attrvalue, %attr) ;
  
  open ATTR, $filename or return undef ;
  local $/ ;   # localized slurp mode
  $filedata = <ATTR> ;
  close ATTR ;
  return undef if $filedata !~ /<attributes>(.*)<\/attributes>/s ;
  $contents = $1 ;
  
  while ($contents =~ /<attr>(.*?)<\/attr>/s)
  {
    $attrdata = $1 ;
    $contents = $' ;    # for next time through
    if ($attrdata !~ /<attrname>(.+)<\/attrname>/s)  # name must have 
                                                     # some length 
    {
      warn "Couldn't find an attrname in -->$attrdata<-- of file $filename\n" ;
    }
    else
    {
      $attrname = $1 ;
      if ($attrdata !~ /<attrvalue>(.*)<\/attrvalue>/s)
      {
        warn 
          "Couldn't find an attrvalue in -->$attrdata<-- of file $filename\n" ;
          $attrvalue = "" ;
      }
      else { $attrvalue = $1 ; }
      $attr{$attrname} = $attrvalue ;
    }
  }
  return %attr ;   # we do this by value to avoid side effects.  May 
                   # need to change. 
}

########################################################################
# finds the previous and next nodes (or anything that translates as    #
# numeric) in a sequence.  Returns a list consisting of                #
# ($prevnodenumber, $nextnodenumber).  Returns empty string ("") for   #
# prevnodenumber if this node is the first in the sequence, or for     #
# nextnodenumber if this node is the last in the sequence, or for      #
# both if the node is not found in the sequence.                       #
########################################################################
sub findPrevNext # ($nodenumber, @sequence)
{
  my ($nodenumber, @sequence) = @_ ;
  my ($prevnodenumber, $nextnodenumber, $foundnode, $numnodes) ;
  $prevnodenumber = $nextnodenumber = "" ;
  $foundnode = 0 ;
  $numnodes = scalar @sequence ;
  for ($i = 0 ; $i < $numnodes ; $i++)
  {
    $foundnode = $sequence[$i] == $nodenumber ;
    if ($foundnode)
    {
      $prevnodenumber = $sequence[$i-1] if $i > 0 ;
      $nextnodenumber = $sequence[$i+1] if $i < $numnodes-1 ;
      last ;
    }
  }
  return ($prevnodenumber, $nextnodenumber) ;
}

sub calcmd5digest # ($filename)
{
  my ($file) = @_ ;
  local (*INMD5) ;
  local ($md5) ;   # does the use of "local" here make sense?  Help efficiency?
  my ($digest) ;
  open INMD5, $file or die "getmd5: couldn't open $file for reading: $!\n" ;
  $md5 = Digest::MD5->new;
  $md5->addfile(*INMD5) ;
  $digest = $md5->hexdigest ;
  close INMD5 ;
  return $digest ;
}

sub getmd5digest # ($flagmd5)
{
  my ($flagmd5) = @_ ;
  return substr $flagmd5, 2, 32 ;
}
sub getmd5isnew # ($flagmd5)
{
  my ($flagmd5) = @_ ;
  return substr $flagmd5, 0, 1 ;
}
sub getmd5isnewanddigest# ($flagmd5)
{
  my ($flagmd5) = @_ ;
  my ($isnew, $digest) ;
  $isnew = substr $flagmd5, 0, 1 ;
  $digest = substr $flagmd5, 2, 32 ;
  return ($isnew, $digest) ;
}

########################################################################
# returns a string to be included as a bug/new feature/improvement     #
# button.  JIRA will open in new window.                               #
########################################################################
sub insertjira # (location)
{
  my ($location) = @_ ;
  my ($result) ;
  $result = <<EOJ;
Report Trace Tree Tool <a href="https://jira1.jpl.nasa.gov:8443/secure/CreateIssueDetails!init.jspa?pid=10000&issuetype=1&priority=6&components=11597&description=LOCATION" target="_blank">Bug</a> | <a href="https://jira1.jpl.nasa.gov:8443/secure/CreateIssueDetails!init.jspa?pid=10000&issuetype=2&priority=6&components=11597&description=LOCATION" target="_blank">New Feature</a> | <a href="https://jira1.jpl.nasa.gov:8443/secure/CreateIssueDetails!init.jspa?pid=10000&issuetype=4&priority=6&components=11597&description=LOCATION" target="_blank">Improvement</a> <i>Not for requirements issues.</i>
EOJ

  $result =~ s/LOCATION/$location/g ;
  return $result ;
}

# issuetype=1 -> Bug
# 2 -> New Feature
# 4 -> Improvement
  
# A set of routines for getting, setting, process status safely.

# This script just queries the status, prints it along with the 
# date/time, and returns a status code as shown below

# State     : meaning or rationale  :  String value in status file
# IDLE      : nothing happening     :  "IDLE"   or file doesn't exist
# DXL_BUSY  : DOORS is dumping data :  "DXL_BUSY"
# DXL_DONE  : DOORS has finished    :  "DXL_DONE"
#           :    dumping data       :
# WGEN_BUSY : Website gen busy      :  "WGEN_BUSY"
# ERROR     : something went wrong  :  "ERROR <text of error message>"

# A GLOBAL.  Write this only with getProcessStatus() or setProcessStatus
$TT_ERROR_MESSAGE = "" ;
$TT_ROOT_PATHNAME = "/data/doors-ttt/data" ;
$TT_STATUS_PATHNAME = $TT_ROOT_PATHNAME . "/" . "LogsAndData/ttstatus.txt" ;
%TT_STATUSES = (
    TT_IDLE      => 0,
    TT_DXL_BUSY  => 1,
    TT_DXL_DONE  => 2,
    TT_WGEN_BUSY => 3,
    TT_ERROR     => 4,
    ) ;

%TT_STATUS_STRINGS = (
    0      => "IDLE",
    1      => "DXL_BUSY",
    2      => "DXL_DONE",
    3      => "WGEN_BUSY",
    4      => "ERROR",
    ) ;

%TT_STATUS_ENGLISH = (
    0      => "Idle",
    1      => "DXL Dump Busy",
    2      => "DXL Dump Done",
    3      => "Website Generation Busy",
    4      => "Status Error",
    ) ;

# Valid only if preceded by getProcessStatus which returned TT_ERROR
sub getProcessErrorStatus   # ()
{
  return $TT_ERROR_MESSAGE ;
}

sub getProcessStatusEnglish  # ($statuscode)
{
    my ($statuscode) = @_ ;
    if ($statuscode < 0 or $statuscode > 4)
    {
        return "unknown status code" ;
    }
    else
    {
        return $TT_STATUS_ENGLISH{$statuscode} ;
    }
}

# setProcessStatus places the correct error string in 
# the $TT_STATUS_PATHNAME file.  It checks that it's a legitimate code,
# but does not check that the transition makes any sense at all.  It
# is NOT a state machine implementation.
# Returns 1 if successful, 0 if not .  Currently, we don't indicate why 
# it failed; it could be either a bogus statuscode, or something wrong
# with the file write.  Maybe $! will be properly set in latter case; 
# needs testing BOZO.
# An error message will only be appended to the status in the file if
# the status is 4, or "ERROR" ("Status Error")

sub setProcessStatus # ($statuscode, $errmess)
{
    my ($statuscode, $errmess) = @_ ;
    if ($statuscode < 0 or $statuscode > 4)
    {
        return 0 ;
    }
    my $statusstring = $TT_STATUS_STRINGS{$statuscode} ;
    my $t ;
    open $t, "> $TT_STATUS_PATHNAME" or return 0 ;
    if ($statuscode == $TT_STATUSES{TT_ERROR})
    {
      $statusstring .= " " . $errmess ;
    }
    print $t $statusstring . "\n" or return 0 ;
    close $t or return 0 ;
    return 1 ;
}



sub getProcessStatus #()
{
    my $returnstatus = -1 ;  # should not happen, will be error
    if (! -e $TT_STATUS_PATHNAME)
    {
        $returnstatus = $TT_STATUSES{TT_IDLE} ;  # maybe a big assumption!
    }
    else
    {
        $result = open S, $TT_STATUS_PATHNAME ;
        if (! $result)
        {
            $returnstatus = $TT_STATUSES{TT_ERROR} ;
            $TT_ERROR_MESSAGE = $! ;
        }
        else
        {
            my @lines = (<S>) ;
            if (scalar(@lines) != 1)
            {
                $returnstatus = $TT_STATUSES{TT_ERROR} ;
                $TT_ERROR_MESSAGE 
                    = " UH OH, $TT_STATUS_PATHNAME contained other than one line" ;
            }
            else
            {
                my $line = @lines[0] ;
                chomp $line ;
                # chomp doesn't always work without some fussing about \r\n
                # So we'll use regexp
                if ($line =~ /^IDLE/) 
                { 
                    $returnstatus = $TT_STATUSES{TT_IDLE} ; 
                }
                elsif ($line =~ /^DXL_BUSY/) 
                { 
                    $returnstatus = $TT_STATUSES{TT_DXL_BUSY} ; 
                }
                elsif ($line =~ /^DXL_DONE/)
                {
                    $returnstatus = $TT_STATUSES{TT_DXL_DONE} ;
                }
                elsif ($line =~ /^WGEN_BUSY/)
                {
                    $returnstatus = $TT_STATUSES{TT_WGEN_BUSY} ;
                }
                elsif ($line =~ /^ERROR (.*)$/)
                {
                    $returnstatus = $TT_STATUSES{TT_ERROR} ;
                    $TT_ERROR_MESSAGE = $1 ;
                }
                else
                {
                    $returnstatus = $TT_STATUSES{TT_ERROR} ;
                    $TT_ERROR_MESSAGE =
                        "$TT_STATUS_PATHNAME contains unknown status '$line'" ;
                }
            }
        }
    }
    # at this point we have an error code.  If it's not ERROR, set
    # error message to ""
    if ($returnstatus != $TT_STATUSES{TT_ERROR})
    {
        $TT_ERROR_MESSAGE = "" ;
    }

    return $returnstatus ;
}
    
1;

