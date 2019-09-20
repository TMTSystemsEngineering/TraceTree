
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
# miscutils.pl
#
# Define $TRUE and $FALSE.  If this conflicts with anything, it's the 
# anything's own damn fault! 

$TRUE = 1 ;
$FALSE = 0 ;

#! printhelpandexit ( $helpmessage [, $specificerrormessage[, $errornumber]]])
#! Case 1:  prints the $helpmessage to STDOUT, exits with status code 0.
#! Case 2:  prints the $helpmessage, a line of dashes, the string '===> ',
#!          and the $specificerrormessage, all to STDERR, exits with 
#!          status code 1.
#! Case 3:  same as Case 2, except exits with status code $errornumber.
#!
# Notes: 
#   $helpmessage may be an empty string or NULL if you only want to print 
#   out a specific error message, in which case the line of dashes will 
#   not be printed. 
#
#   The idea is that if you have a specific error message to print out, 
#   there's been a user error of some sort, and you want the messages to 
#   go to STDERR, and if you haven't specified an error number, you want 
#   to exit with some arbitrary non-zero value.  We choose 1. 
#
#   New-lines will be added to the string messages if there weren't any 
#   there already. 

sub printhelpandexit
{
  ($helpmessage, $specificerrormessage, $errno) = @_ ;
  chomp $helpmessage ;
  if (defined ($specificerrormessage))
  {
    chomp $specificerrormessage ;
    print STDERR "$helpmessage\n" .
"-----------------------------------------------------------------------\n" 
    if $helpmessage;
    print STDERR "===> $specificerrormessage\n" ;
    exit $errno if defined $errno ;
    exit 1 ;
  }
  else
  {
    print STDOUT "$helpmessage\n" ;
    exit 0 ;
  }
}

sub commafy 
{
  ($_) = @_ ;
  #  Code from perlop man page, so presumably Larry Wall's?
  # 1 while s/(.*\d)(\d\d\d)/$1,$2/g;      # perl4
  1 while s/(\d)(\d\d\d)(?!\d)/$1,$2/g;  # perl5
  return $_ ;
}

sub tabexpand
{
  my ($lines) = @_ ;
  my ($nlonend, $outlines, @lines, $line) ;

  $nlonend = chomp $lines ;   
  @lines = split /\n/, $lines, -1;   # -1 to force nulls on end to be 
                                     # retained.
  while ($line = shift @lines)
  {
    1 while $line =~ s/\t+/' ' x (length($&)*8 - length($`)%8)/e;
    $outlines .=  @lines ? "$line\n" : $line ; # Add back \n unless this 
                                               # is last line. 
  }
  $outlines .= "\n" if $nlonend ;   # And the last one too if there was 
                                    # one there originally. 
  return $outlines ;
}

#  Logic of following is from perlop man page, presumably from Larry 
#  Wall. 
sub tabexpandline
{
  my ($line) = @_ ;
  1 while $line =~ s/\t+/' ' x (length($&)*8 - length($`)%8)/e;
  return $line ;
}

sub findprocps 
#! Usage: $string  = findprocps (regexp, psflags, includeheader) ;
#!    or: %pidlist = findprocps (regexp, psflags, includeheader) ;
#! Where [defaults in square brackets]:
#!    regexp          is the regular expression with which to match
#!                    lines of the output of ps(1) 
#!    psflags         are the flags to use with the ps(1) command [-a]
#!    includeheader   include the header line that ps(1) outputs 
#!                    [false, implies don't]
#
# Finds pids of processes whose ps lines match the regular expression 
# 'regexp'.  The system program 'ps' is called with whatever flags are 
# specified in the string psflags. 
#
# For a scalar return, a string containing all the lines that matched, 
# optionally including ps's header line, is returned.  If no lines 
# matched, the header line is not return even if includeheader is TRUE,
# so that a test against an empty string tell the caller if there
# were any matches.
#
# For an array return, a hash with keys consisting of the pids that were 
# matched is returned.  The values are the corresponding lines from the 
# ps output.  If including the header, the header's key is 'header'. 
#
# findprocps purposely dies if an error occurs, since messing around 
# with processes in that event is Bad. 
{
  local ($regexp, $psflags, $inclhdr) = @_ ;
  local ($cmdpart, $cmdstart, $cmdstring, $firstline, $line,
      $pid, $pidstart, $pidpart, @ps, @psmatch,
      $returnval, %lineOf) ;

  $psflags = '-a' if ! defined ($psflags) ;
  $psflags =~ s/^([^-])/-$1/ ;   # put a dash on the front if there 
                                 # isn't any 
  $cmdstring = "ps $psflags" ;
  open (CMD, "$cmdstring |") 
    or die "Couldn't open pipe from $cmdstring: $!\n" ;
  @ps = (<CMD>) ;
  close CMD ;
# print STDERR "result of '$cmdstring' is @ps\n" ;

  # We'll need the first line to determine where PID is.
  $firstline = shift @ps ;

  # Eliminate anything that doesn't match.
  @psmatch = grep /$regexp/, @ps ;

  # We'd be done if it weren't for the fact it's likely that whatever 
  # program called findprocps has the search string in its command line, 
  # and therefore could turn up in the ps list.  It's doubtful, however, 
  # that the ps command itself would be there.  Isn't it? Well, except 
  # in rare cases, we can get rid of the ps command based on a match 
  # between the CMD and the cmdstring. So we have to go ahead and 
  # find the PIDs and CMDs, wherever they are. 

  # Look for ' PID'.  Don't just look for 'PID', which includes 'PPID'.
  # We make the brazen assumption that pids are now and ever will be
  # 5 characters max.  This relieves us of  the burden of trying to
  # figure out the actual boundary between PID and whatever precedes
  # it.  The data and column header seem to be right-justified.

  ######################################################################
  # ACTUALLY NONE OF THIS WORKS NOW (2011 Feb).  If the "User" field   #
  # exceeds a certain length, everything else gets bumped to the       #
  # right.  So the CMD and particularly the PID fields get added       #
  # spaces on the left and PID gets truncated on the right.  NFG.      #
  ######################################################################
  # Following just happens to work!

  ######################################################################
  # SO THIS IS ALL THE OLD STUFF BASED ON CHARACTER POSITION           #
  ######################################################################
  # if ($firstline =~ /\s+PID\b/) { $pidstart = length ($`) + length ($&) - 5 ; }
  # else { die "Couldn't find 'PID' in the first ps line:$firstline\n" ; }
  
  # # CMDs are always last.  So far.
  # if ($firstline =~ /(CMD|COMMAND)\s/) { $cmdstart = length $` ; }
  # else { die "Couldn't find 'CMD or COMMNAND' in the first ps line:$firstline\n" ; }

  # Now we have to go with field index
  # Now we figure out both the CMD and PID fields for each line
  my @fields = split /\s+/, $firstline ;
  my $fieldindex ;
  my ($pidindex, $cmdindex) = (-1, -1) ;
  for ($fieldindex = 0 ; $fieldindex < scalar(@fields) ; $fieldindex++)
  {
    $pidindex = $fieldindex if $fields[$fieldindex] eq 'PID' ;
    $cmdindex = $fieldindex if $fields[$fieldindex] =~ /(CMD|COMMAND)/ ;
  }
  die "findprocps: Couldn't find PID and/or CMD|COMMAND in ps header lined\n" 
      if $pidindex == -1 or $cmdindex == -1 ;

  foreach $line (@psmatch)
  {
    chomp $line ;
    @fields = split /\s+/, $line ;
    # OLD $pidpart = substr ($line, $pidstart, 5) ;
    # OLD $pidpart =~ /\b(\d+)$/ ;
    # OLD $pid = $1 ;
    $pid = $fields[$pidindex] ;
    next if $pid == $$ ;    # TRASH this process's own entry.

    # OLD $cmd = substr ($line, $cmdstart) ;
    # OLD $cmd =~ s/^\s+// ;  # cuz ps -u isn't quite aligned with header line 
    $cmd = join " ", $fields[$cmdindex .. $#fields] ;
    # next might no longer work since it's not quite verbatim...
    next if $cmd eq $cmdstring ;   # TRASH the ps process's entry

    $lineOf{$pid} = $line ;
#   $cmdOf{$pid} = $cmd ;   # We don't use this at the moment
  }

  if (wantarray())
  {
    $lineOf{'header'} = $firstline if $inclhdr ;
    return %lineOf ;   # we return the entire hash
  }
  else
  {
    # return empty string if nothing found
    return "" if ! %lineOf ;
    # start with header if desired
    $returnval = $firstline if $inclhdr ;  # $firstline not chomped
    # put'em in order
    foreach (sort keys (%lineOf))
    {
      $returnval .= $lineOf{$_} . "\n" ;
    }
    return $returnval ;
  }
}

sub findlongest
{
  my ($max) ;
  $max = 0 ;
  $i = 1 ;

  foreach (@_)
  {
    if (length > $max)
    {
      $max = length ;
      $linenumber = $i ;
    }
    $i++ ;
  }
  return wantarray ? ($max, $linenumber) : $max ;
}

# (@pgmresult, @sysresult) = splitresult ($result)
sub splitresult
{
  local ($result) = @_ ;
  local ($sysbyte, $pgmbyte) ;   # same as rightbyte/lobyte,
                                 # leftbyte/hibyte
  $sysbyte = $result & 0xFF ;
  $pgmbyte = ($result & 0xFF00) >> 8 ;
  return ($pgmbyte, $sysbyte) ;
}

sub cmpbypairnumeric
{
  return $$a[1] <=> $$b[1] ;
}

sub time24to12 # ($hour)    input $hour must be in range 0 to 23
               # returns list (new hour in range 1 to 12, string "AM" or "PM")
{
  my ($lhour) = @_ ;
  my ($ohour, $ampm) ;

  if    ($lhour == 0)  { $ohour = 12        ; $ampm = "AM" ; }
  elsif ($lhour < 12)  { $ohour = $lhour    ; $ampm = "AM" ; }
  elsif ($lhour == 12) { $ohour = 12        ; $ampm = "PM" ; }
  elsif ($lhour < 24)  { $ohour = $lhour-12 ; $ampm = "PM" ; }
  else                 { $ohour = undef     ; $ampm = undef ; }
  return ($ohour, $ampm) ;
}

sub compareLists # (\@l1, \@l2)
{
  my ($l1ref, $l2ref) = @_ ;
  return $FALSE if $#$l1ref != $#$l2ref ;   # different length arrays get false
  for ($i = 0 ; $i <= $#$l1ref ; $i++) 
  { 
    return $FALSE if $$l1ref[$i] ne $$l2ref[$i] ; 
  }
  return $TRUE ;
}

sub intaway # (afloatnumber)
{
  my ($f) = @_ ;
  my ($i) = int($f) ;
  return ($i) if $i == $f ;
  if ($f > 0.0) { return $i+1 ; } else { return $i-1 ; }
}

sub inttoward # (afloatnumber)
{
  my ($f) = @_ ;
  my ($i) = int($f) ;
  return $i ;    # this one's the same behavior as int
}

sub intup # (afloatnumber)
{
  my ($f) = @_ ;
  my ($i) = int($f) ;
  return ($i) if $i == $f ;
  if ($f > 0.0) { return $i+1 ; } else { return $i ; }
}

sub intdown # (afloatnumber)
{
  my ($f) = @_ ;
  my ($i) = int($f) ;
  return ($i) if $i == $f ;
  if ($f > 0.0) { return $i ; } else { return $i-1 ; }
}
sub readtsvfile
{
  my ($fname) = @_ ;
  my ($inlines, @inrows) ;
  local *I ;

  open I, $fname or die "Couldn't open $fname for reading: $!\n" ;
  local $/ = undef ;
  $inlines = <I> ;   # scarf'em all up   
  $inlines =~ s/\r\n/\r/g ;    # necessary, considering it's coming from Mac?
  $inlines =~ s/\n/\r/g ;
  @inrows = readtsv ($inlines) ;  # returns a list of references to 
                                  # lists of fields 
  return \@inrows ;
}


sub readtsv # (allthelinestogether)
{
# a tsv file has a couple of rules besides tab separation.
#  - if there's a quote, tab, or newline in the field, the field is quoted
#  - a quote looks like ""
#  - a tab looks like bare \t within body of field
#  - a newline looks like bare \n (or \r) within body of field
  my ($inlines) = @_ ;
  my (@fields, $rowref, @rows) ;

  while (length $inlines > 0) 
  {
    @fields = parsetsvrecord (\$inlines) ;
    $rowref = [@fields] ;
    push @rows, $rowref ;
  }
  return @rows ;
}

sub parsetsvrecord
{
  my ($dref) = @_ ;
  my ($notdone) = 1 ;
  my (@fields) ;
  my ($field) ;
  my ($iseol) ;

  do
  {
    ($field, $iseol) = getonefield ($dref) ;
    push @fields, $field ;
  } until ($iseol) ;
  return @fields ;
} 
sub getonefield
{
  my ($dref) = @_ ;
  my ($field, $tabindex, $nlindex, $qtindex, $qtqtindex, $endindex, $eol ) ;

  if ( $$dref !~ /^"/ )    # then it's normal
  {
    $tabindex = index $$dref, "\t" ;
    $nlindex = index $$dref, "\r" ;       # oughta make this parametric...
    if ($nlindex == -1 && $tabindex == -1)   # then it's end of file, pretend \n
    {
      $nlindex = length $$dref ;  # one beyond
    }
    if ($tabindex == -1 || ($nlindex > -1 && $tabindex > $nlindex))   # then it's end of line
    {
      $endindex = $nlindex ; 
      $eol = 1 ;  # is eol
    }
    else # tabindex < nlindex (can't be ==) - it's not eol
    {
      $endindex = $tabindex ;
      $eol = 0 ;   # it isn't eol
    }
    # abcdefg\t     endindex is 7 in this case
    # 01234567
    $field = substr $$dref, 0, $endindex ;   # don't want the tab or nl
    (substr $$dref, 0, $endindex+1) = "" ;     # now get rid of field and delim
    return ($field, $eol) ;
  }
  else         # Uh, oh, it's not normal
  {
    $qtindex = index $$dref, '"', 1 ;  # what if $$dref is already too short?
    $qtqtindex = index $$dref, '""', 1 ;
    while ($qtindex == $qtqtindex)    # found a legit escaped quote character
    {
      # asdf""zxcv     qtindex is 4, in this example
      # asdf"zxcv     qtindex is 4, in this example
      # 012345678
      (substr $$dref, $qtqtindex, 1) = "" ; # get rid of one quote
      $qtindex   = index $$dref, '"', $qtqtindex+1 ;   # look after what you've
      $qtqtindex = index $$dref, '""', $qtqtindex+1 ;   # already found
    }
    # OK, found an unquoted quote.  So it's the end of a field.  But we don't
    # want either it or the beginning quote.
    # "asdf"    qtindex is 5 and length of field is 4
    # 012345    
    $field = substr $$dref, 1, $qtindex-1 ;
    (substr $$dref, 0, $qtindex+1) = "" ;    # now get rid of field and quotes
    # next character should never be anything but tab, eol, or eof
    $eol = 1 ;     # either eol or eof
    if ((length $$dref > 0) 
       and (substr $$dref, 0, 1, "") eq "\t") 
    { 
      $eol = 0 ; 
    }
    return ($field, $eol) ;
  }


}

sub writetsv # (@rows) reference to rows of fields
{
       # returns a single scalar containing the entire table in tsv
       # format with \r as line separator, and empty fields at end to
       # fill in to max number of fields

  my (@rows) = @_ ;
  my ($maxnfields, $i, $rowref, @fields, $nfields, $result) ;
  my ($j, $field) ;
  $maxnfields = 0 ;
  for ($i = 0 ; $i < scalar @rows ; $i++)
  {
    $rowref = $rows[$i] ;
    @fields = @$rowref ;    # if we combined these, would it be faster?
    $nfields = scalar @fields ;
    $maxnfields = $maxnfields > $nfields ? $maxnfields : $nfields ;
  }

  $result = "" ;
  for ($i = 0 ; $i < scalar @rows ; $i++)
  {
    $rowref = $rows[$i] ;
    @fields = @$rowref ;
    $nfields = scalar @fields ;
    for ($j = 0 ; $j < $nfields ; $j++)
    {
      $field = $fields[$j] ;
      # do we need to quote this field?
      if ($field =~ /["\r\n\t]/)
      {
	# if there are quotes in it, double them
	$field =~ s/\"/\"\"/g ;
	$field = '"' . $field . '"' ;
      }

      $result .= $field ;
      $result .= "\t" if $j < $maxnfields-1 ;  # add a tab if between fields
    }
    # a little brute force, but ...
    for ($j = $nfields ; $j < $maxnfields ; $j++)
    {
      $result .= "\t" if $j < $maxnfields-1 ;  # add a tab if between fields
    }

    $result .= "\r" if $i < (scalar(@rows)-1) ;  # add newline only at end
  }
  return $result ;
}

########################################################################
# pass in path only, not filename, e.g., if current html file (if      #
# that's what we're dealing with is /a/b/c/qwer.html, pass in          #
# /a/b/c/, or /a/b/c .  "/" at beginning or end is assumed and ignored #
########################################################################
sub genrelativepath
{
  my ($srcpath, $targetpath) = @_ ;
  my (@s, @t) ;
  my ($result, $t) ;

  $srcpath =~ s/^\/// ;
  $srcpath =~ s/\/$// ;
  $targetpath =~ s/^\/// ;
  $targetpath =~ s/\/$// ;
  @s = split /\//, $srcpath ;
  @t = split /\//, $targetpath ;
  while (@s && @t)
  {
    if ($s[0] eq $t[0]) { shift @s ; shift @t ; }
    else { last ; }
  }
  $result = "" ;
  while (@s)
  {
    shift @s ;
    $result .= "../" ;
  }
  # if it has anything, result ends with '/'
  while (@t)
  {
    $t = shift @t ;
    $result .= $t . "/" ;
  }
  return $result ;
}

# uniq - given a sorted list, returns list with duplicates removed.
sub uniq 
{
  my (@inlist) = @_ ;
  my (@outlist) ;
  my ($a, $preva) ;

  foreach $a (@inlist)
  {
    if (!defined $preva)    # which would happen if first in list
    {
      $preva = $a ;
      push @outlist, $a ;
    }
    else
    {
      push @outlist, $a unless $a eq $preva ;
      $preva = $a ;
    }
  }
  return @outlist ;
}

sub round
{
  my ($x) = @_ ;
  my ($isneg) = ($x < 0) ;
  my ($i) ;

  $x = -$x if $isneg ;
  $i = int ($x+0.5) ;
  $i = -$i if $isneg ;
  return $i ;
}

########################################################################
# convert days to days,hours, minutes, seconds, fractional seconds     #
########################################################################
sub dhms
{
  my ($days) = @_ ;
  my $idays = int ($days) ;

  my $hours = ($days - $idays) * 24 ;
  my $ihours = int ($hours) ;

  my $mins = ($hours - $ihours) * 60 ;
  my $imins = int ($mins) ;

  my $secs = ($mins - $imins) * 60 ;
  my $isecs = int ($secs) ;

  my $fracsec = ($secs - $isecs) ;

  return ($idays, $ihours, $imins, $isecs, $fracsec) ;
}
########################################################################
# convert hours to hours, minutes, seconds, fractional seconds         #
########################################################################
sub h2hms
{
  my ($hours) = @_ ;

  my $ihours = int ($hours) ;

  my $mins = ($hours - $ihours) * 60 ;
  my $imins = int ($mins) ;

  my $secs = ($mins - $imins) * 60 ;
  my $isecs = int ($secs) ;

  my $fracsec = ($secs - $isecs) ;

  return ($ihours, $imins, $isecs, $fracsec) ;
}

########################################################################
# convert seconds to hours, minutes, seconds, fractional seconds       #
########################################################################
sub s2hms
{
  my ($seconds) = @_ ;
  return h2hms ($seconds/3600) ;
}

########################################################################
# sleepdown - similar to sleep, but with a countdown message on a      #
# single line.  Doesn't return error codes - probably should, BOZO.    #
########################################################################
sub sleepdown # (sleeptime) - an integer number of seconds
{
  my ($sleep) = @_ ;
  my ($starttime, $endtime, $left, $ds) ;
  $starttime = time ;
  $endtime = $starttime + $sleep ;

  while (time < $endtime) 
  {
    $left = $endtime - time ;
    print STDERR "\r" . $left . "\e[K" ;
    last if $left < 1 ;
    $ds = int(log($left) ) ;
    $ds ++ if !$ds ;
    sleep $ds ;
  }
  print STDERR "\r                                      \r" ;
}


1;

