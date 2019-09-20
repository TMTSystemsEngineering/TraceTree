
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
########################################################################
# finds the data within 'indata' which is between <tag> and </tag>,    #
# if any. returns undef if none.  If 'which' is defined, it will find  #
# the whichth occurrence of the tag, again return undef if there       #
# isn't any whichth occurrence.  'Which' starts with 1. This is all    #
# done brute force - strings are copied all over the place, indices    #
# within strings aren't saved between calls, etc.                      #
########################################################################
sub simpleGetXMLData # (string indata, string tag, int which=0) 
                     # return string outdata
{
  my ($indata, $tag, $which) = @_ ;
  my ($stag, $etag, $pos, $i, $data) ;
  my ($staglen, $etaglen) ;
  my ($sindex, $eindex, $sdata) ;
  $which = 1 if ! defined $which ;
  $stag = "<$tag>" ;  $staglen = length $stag ;
  $etag = "</$tag>" ;  $etaglen = length $etag ;
  $pos = 0 ;
  for ($i = 0 ; $i < $which ; $i++)
  {
    $sindex = index $indata, $stag, $pos ;
    last if $sindex == -1 ;     # finish with undef if not found
    $sdata = $sindex + $staglen ; # if all goes well
    $eindex = index $indata, $etag, $sdata ;  # start searching for end 
                                              # tag at start of data 
    last if $eindex == -1 ;     # finish with undef if end tag not found 
    $pos = $eindex + $etaglen ;  # next time through, if any, we start 
                                 # after last discovered end tag 
  }
  ######################################################################
  # OK, at this point, we have data if sindex and eindex are both >    #
  # 0.  If so, sdata will point to the start of the data, and eindex   #
  # to the position after its end.  But sdata itself is NOT the        #
  # proper test.                                                       #
  ######################################################################
  if ($sindex >= 0 and $eindex >= 0) 
  {
    $data = substr $indata, $sdata, ($eindex-$sdata) ;
  }
  else
  {
    $data = undef ;
  }
  return $data ;
}

########################################################################
# THIS DOESN'T WORK AT ALL WITH NESTED TAGS OF SAME NAME!!!            #
########################################################################
########################################################################
# finds the string indices of data within 'indata' which is between    #
# <tag> and </tag>, if any, starting at startindex, or index=0 if      #
# startindex is not defined, and ending at endindex, or end of the     #
# data if endindex is not defined.  Returns a list consisting of       #
# (dataindex, datalen, nextstartindex), where dataindex will be set    #
# to undef if nothing is found                                         #
########################################################################
sub simpleGetXMLindices # (string indata, string tag, 
                        # int startindex=0, 
                        # int endindex=0) 
                        # return (dataindex, datalen, nextstartindex) 
{
  my ($indata, $tag, $startindex, $endindex) = @_ ;
  my ($stag, $etag, $nextpos, $i, $data) ;
  my ($staglen, $etaglen) ;
  my ($sindex, $eindex, $sdata) ;
  $startindex = 0 if ! defined $startindex ;
  $endindex = length($indata) if ! defined $endindex ;

  $stag = "<$tag>" ;  $staglen = length $stag ;
  $etag = "</$tag>" ;  $etaglen = length $etag ;

  $sindex = index $indata, $stag, $startindex ;
  # return undef if nothing found or if there's no room left for an end tag
  return (undef, undef, undef) if ($sindex == -1 or $sindex >= ($endindex-etaglen)) ;

  # found something within the range specified
  $sdata = $sindex + $staglen ; # if all goes well

  $eindex = index $indata, $etag, $sdata ;  # start searching for end 
					    # tag at start of data 
  # return undef if no end tag found or if end tag ended after search range
  return (undef, undef, undef) if ($eindex == -1 or $eindex >= ($endindex-$etaglen)) ;

  # OK, we found it.
  $nextpos = $eindex + $etaglen ;  # next time through, if any, we start 
                                 # after last discovered end tag 

  return ($sdata, $eindex-$sdata, $nextpos) ;
}

1;
