
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
use Spreadsheet::WriteExcel;
use Spreadsheet::ParseExcel;
require "excutils.pl" ;

########################################################################
# readexcdb - read a database from an excel workbook.  Very            #
# unsophisticated - no links, etc.  Returns a list of tables parsed    #
# into hashes.  Each table assumed to be stored in a single worksheet  #
# of the workbook.  The IDs for the worksheets are assumed to be in a  #
# column named "ID".  For now, we assume order doesn't matter.  That   #
# may have to change.                                                  #
########################################################################
sub readexcdb # ($filename)
{
  my ($filename) = @_ ;
  
  my $parser = Spreadsheet::ParseExcel->new() ;   # create a parser
  my $workbook = $parser->Parse ($filename) ;
  return undef unless defined($workbook) ;
  print STDERR "Got past return undef\n" ;
  
  my $sheetcount = $workbook->{SheetCount} ;
  my @result ;
  my @tablenames ;
  my @tablerefs ;
  my %tableOf ;
  my $tablenameref ;
  # no way to use these yet ...
  my $isheet ;
  for ($isheet = 0 ; $isheet < $sheetcount ; $isheet++)
  {
    my $worksheet = $workbook -> Worksheet($isheet) ;
    if (!defined $worksheet)
    {
      warn "Couldn't parse sheet '$isheet' from workbook '$filename'\n" ;
      next ;
    }
    $wsname = $worksheet -> {Name} ;
    push @tablenames, $wsname ;
  }
  $tablenameref = [@tablenames] ;



  
  @tables = ("a", "b") ;


  print STDERR "Gonna return @tables\n" ;
  return \@tables ;
}


1;
