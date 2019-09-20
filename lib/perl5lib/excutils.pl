
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
use Spreadsheet::ParseExcel;

########################################################################
# Starting from rowmin and colmin as returned from the worksheet,      #
# search for column header (or anything, really) using $searchstring   #
# as an exact string to look for.  Returns ($row, $col) at which       #
# string was found, or (-1, -1) if not found.  Searches row-wise,      #
# i.e., varying the column most rapidly.                               #
########################################################################
sub findColHeader # ($ws, $searchstring)
{
  my ($ws, $ss) = @_ ;
  die "findColHeader: undefined worksheet" 
      unless defined $ws ;
  my ($rowmin, $rowmax) = $ws->row_range() ;
  my ($colmin, $colmax) = $ws->col_range() ;
  
  my $foundit = 0 ;

  my ($row, $col) ;
  for ($row = $rowmin ; $row <= $rowmax ; $row++)
  {
    for ($col = $colmin ; $col <= $colmax ; $col++)
    {
      my $field = getstringfrom ($ws, $row, $col) ;
      if (defined $field and $field eq $ss)
      {
        $foundit++ ;
        last ;
      }
    }
    last if $foundit ;
  }
  return ($row, $col) if $foundit ;
  return (-1, -1) ;
}

########################################################################
# Gets the header row information from a worksheet.  Returns an array  #
# of strings from the first row in a spreadsheet, taking row_range as  #
# determined by ParseExcel to be the first row.  The array will have   #
# col_range entries in it.  That is, if col_range returns (2,10), the  #
# returned array will have 9 entries.  If there's no data in a         #
# presumed header cell, the corresponding entry in the array will      #
# have an empty string.                                                #
########################################################################
sub getheaderrow # ($ws)   # could augment this with more options...
{
  my ($ws) = @_ ;
  die "getheaderrow: undefined worksheet"
      unless defined $ws ;
  my ($rowmin, $rowmax) = $ws->row_range() ;
  my ($colmin, $colmax) = $ws->col_range() ;
  my (@result) ;
  my $len = $colmax-$colmin+1 ;
  $#result = $len ;
  my ($i, $val) ;
  for ($i = 0 ; $i < $len ; $i++)
  {
    $val = getstringfrom ($ws, $rowmin, $colmin+$i) ;
    if (!defined $val) { $result[$i] = '' ; }
    else               { $result[$i] = $val ; }
  }
  return @result ;
}

########################################################################
# Gets the header row information from a worksheet, returning hash of  #
# column numbers indexed by header row contents.                       #
########################################################################
sub getheaderrowhash # ($ws)
{
  my ($ws) = @_ ;
  die "getheaderrowhash: undefined worksheet"
      unless defined $ws ;
  my ($rowmin, $rowmax) = $ws->row_range() ;
  my ($colmin, $colmax) = $ws->col_range() ;
  my (%result) ;
  my $len = $colmax-$colmin+1 ;
  my ($i, $val) ;
  for ($i = 0 ; $i < $len ; $i++)
  {
    $val = getstringfrom ($ws, $rowmin, $colmin+$i) ;
    if (defined $val and $val ne '') 
    { $result{$val} = $colmin + $i ; }
  }
  return %result ;
}


########################################################################
# Get the unformatted string from a given cell in a given worksheet.   #
# Should return undef if nothing there, but doesn't seem to do that.   #
# More testing needed, BOZO.                                           #
########################################################################
sub getstringfrom # ($worksheet, $row, $col)
{
  my ($worksheet, $row, $col) = @_ ;
  my ($cell, $field) ;

  # print "getstringfrom called with row=$row col=$col\n" ;

  $cell = $worksheet -> Cell($row, $col) ;
  if (defined $cell) 
  { 
    $field =  $cell->unformatted() ;
# print STDERR "returning field = '$field'\n" ;
    return $field ;
  }
  else
  {
# print STDERR "RETURNING FIELD = UNDEF\n" ;
    return undef ;
  }
}

########################################################################
# Given a worksheet, a row, a column, and optionally an array of       #
# ranges as defined by Spreadsheet::ParseExcel, return a value         #
# whether the cell is in a merged range or not.  Gives no indication   #
# of whether the cell is in a merged range.  returns undefined if the  #
# cell is undefined.  In the case of a merged range, used the value    #
# found in the upper-left corner of the merged range.  Essentially,    #
# always give me a value.  Returns the unformatted value unless the    #
# type is Date, in which case it uses "value() - i.e., the formatted   #
# value                                                                #
########################################################################
sub mergedValAlways
{
  my ($ws, $row, $col, $mareas) = @_ ;
  die "mergedValAlways: ws not defined\n" if !defined $ws ;
  my $cell = $ws -> Cell ($row, $col) ;
  return undef if !defined $cell ;
  my ($val, $type) ;
  if ($cell->{Merged}) # then we have to do it
  {
    ####################################################################
    # Get the merged ranges unless already defined.  Don't bother to   #
    # check undefined, we know there are merged areas because $cell    #
    # said so                                                          #
    ####################################################################
    $mareas = $ws->{MergedArea} unless defined $mareas ;

    # check each area
    my $ma ;
    my $foundit = 0 ;
    foreach $ma (@$mareas)
    {
      my $isin = isInRange ($row, $col, $ma) ;
      if ($isin)
      {
	################################################################
	# need to get the value that's at the sr, sc position of       #
	# merged area                                                  #
	################################################################
	my ($sr, $sc) = ($ma->[0], $ma->[1]) ;
	my $ulcell = $ws -> Cell ($sr, $sc) ;
	die "mergedValAlways: undefined cell starting range, sr,sc=$sr,$sc\n" 
	    if !defined $ulcell ;
	$type = $ulcell->{Type} ;
	if ($type eq 'Date')
	{
	  $val = $ulcell->value() ;
	}
	else
	{
	  $val = $ulcell->unformatted() ;
	}
	$foundit++ ;
	last ;
      }
    }
    die "mergedValAlways: couldn't find merged cell in merged ranges, " . 
	"r,c = $row, $col\n" 
	    if  !$foundit ;
  }
  else
  {
    $type = $cell->{Type} ;
    if ($type eq 'Date')
    {
      $val = $cell->value() ;
    }
    else
    {
      $val = $cell->unformatted() ;
    }
  }
  return $val ;
}



########################################################################
# given a row, a column and a reference to a range (by reference) as   #
# defined by Spreadsheet::ParseExcel, is the row and column in the     #
# range?                                                               #
########################################################################
sub isInRange
{
  my ($row, $col, $marea) = @_ ;
      
  my ($sr, $sc, $er, $ec) = @$marea ;
  return (    $row >= $sr and $row <= $er 
          and $col >= $sc and $col <= $ec) ;
}


1;
