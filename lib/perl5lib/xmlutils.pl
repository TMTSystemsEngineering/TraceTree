
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

sub gettoplevelattrs
{
  # ModDate ModDateType ModuleName ObjectNumber Paragraph ProjectName
  # ReportDate isOutline objURL

  my ($ref) = @_ ;
  my ($topreftype) ;
  my ($ModDate, $ModDateType, $ModuleName, $ObjectID, $ObjectNumber) ;
  my ($ProjectName, $ReportDate, $isOutline, $objURL) ;
  my ($isTableHeader, $isTableRow, $isTableCell) ;
  my (@result) ;

  $isOutline = 0 ;
  $topreftype = ref ($ref) ;
  if ($topreftype ne "HASH")
  {
    warn "top level ref type is not HASH, is $toreftype\n" ;
    @result = () ;
  }
  else
  {
    $ModDate = $$ref{"ModDate"} if defined $$ref{"ModDate"} ;
    $ModDateType = $$ref{"ModDateType"} if defined $$ref{"ModDateType"} ;
    $ModuleName = $$ref{"ModuleName"} if defined $$ref{"ModuleName"} ;
    $ObjectID = $$ref{"ObjectID"} if defined $$ref{"ObjectID"} ;
    $ObjectNumber = $$ref{"ObjectNumber"} if defined $$ref{"ObjectNumber"} ;
    $ProjectName = $$ref{"ProjectName"} if defined $$ref{"ProjectName"} ;
    $ReportDate = $$ref{"ReportDate"} if defined $$ref{"ReportDate"} ;
    $isOutline = $$ref{"isOutline"} eq "true" if defined $$ref{"isOutline"} ;
    $objURL = $$ref{"ObjectURL"} if defined $$ref{"ObjectURL"} ;
    $isTableHeader = $$ref{"isTableHeader"} eq "true" 
        if defined $$ref{"isTableHeader"} ;
    $isTableRow = $$ref{"isTableRow"} eq "true" 
        if defined $$ref{"isTableRow"} ;
    $isTableCell = $$ref{"isTableCell"} eq "true" 
        if defined $$ref{"isTableCell"} ;
    @result = ($ModDate, $ModDateType, $ModuleName, $ObjectID, $ObjectNumber, 
               $ProjectName, $ReportDate, $isOutline, $objURL,
	       $isTableHeader, $isTableRow, $isTableCell) ;
  }

  return @result ;
}

1;
