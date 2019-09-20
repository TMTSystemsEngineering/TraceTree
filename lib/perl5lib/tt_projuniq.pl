
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

sub getProjectUniq # ($pname)
{
  my ($pname) = @_ ;
  my $doNotVap = ($pname eq "DSN" or $pname eq "SES_JUNO") ;
  my $doProjID = '' ;
  $doProjID = '[P] Heritage ID' if $pname eq "MSM" ; 
  $doProjID = 'TMT ID' if $pname eq "TMT_Requirements" ; 
  
  print STDERR "Project Uniq variables for $pname:\n" ;
  print STDERR "  doNotVap = $doNotVap\n" ;
  print STDERR "  doProjID = '$doProjID'\n" ;
  return ($doNotVap, $doProjID) ;
}


########################################################################
# getpertinenttxt assumes all texts are single lines.  It's supposed   #
# to be that way as written by xxmlobjtxt                              #
########################################################################
#  ($objtxt, $shrttxt, $projidtxt, $vaptxt)  = 
sub getpertinenttxt
{
  my ($fname) = @_ ;
  my $objtxt = '';
  my $shrttxt = '';
  my $projidtxt = '';
  my $vaptxt = '';
  local *PERTTXT ;

  open PERTTXT, "$fname"
      or die "Couldn't open perttxt file $fname for reading: $!\n" ;
  while (<PERTTXT>)
  {
    chomp ;
    if (/^(.*?):\t(.*)$/)
    {
      my $key = $1 ;
      my $val = $2 ;
      $val =~ s/\\/\\\\/g ;   # backslash-quote any backslashes - needed?
# print STDERR "'$fname' key=$key\n" ;
      if ($key eq 'object text') { $objtxt = $val ; }
      elsif ($key eq 'short text') { $shrttxt = $val ; }
      elsif ($key eq 'ProjID') { $projidtxt = $val ; }
      elsif ($key eq 'VAP text') { $vaptxt = $val ; }
      else
      {
	die "$0: file $fname contains incorrect line: '$_'\n" ;
      }
    }
  }
  close PERTTXT ;
# print STDERR "returning o='$objtxt', s='$shrttxt', p='$projidtxt', v='$vaptxt'\n" ;
  return ($objtxt, $shrttxt, $projidtxt, $vaptxt) ;
}

# getprojidtxt is going to assume that the Project ID is a single line, no 
# matter what.  xxmlobjtxt should write it that way.
sub getprojidtxt
{
  my ($fname) = @_ ;
  my $projidtxt = '';
  local *PERTTXT ;

  open PERTTXT, "$fname"
      or die "Couldn't open perttxt file $fname for reading: $!\n" ;
  my $foundone = 0 ;
  while (<PERTTXT>)
  {
    chomp ;
# print STDERR "getprojid: \$_ = '$_'\n" ;
    if (/^ProjID:\t(.*)$/)
    {
# print STDERR "Inside if... " ;
      $projidtxt = $1 ;
      $foundone++ ;
# print STDERR " projidtxt = $projidtxt\n" ;
      last ;
    }
  }
  print STDERR "$0: Couldn't find expected ProjID: line in '$fname'\n" 
      unless $foundone ;
  $projidtxt =~ s/\\/\\\\/g ;   # backslash-quote any backslashes - needed?
  close PERTTXT ;
# print STDERR "returning $projidtxt\n" ;
  return $projidtxt ;  # for now
}

1;
