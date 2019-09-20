
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
use Time::Local ;

# should use constant here...
# object-level stats
$countconst                 = 0 ;
$MOBJ_MODDATE               = $countconst++ ;
$MOBJ_MODDATETYPE           = $countconst++ ;
$MOBJ_MODDATEINT            = $countconst++ ;
$MOBJ_OBJNUM                = $countconst++ ;
$MOBJ_ISHEADING             = $countconst++ ;
$MOBJ_ISTABLEHEADER         = $countconst++ ;
$MOBJ_ISTABLEROW            = $countconst++ ;
$MOBJ_ISTABLECELL           = $countconst++ ;
$MOBJ_ISTABLEPART           = $countconst++ ;
$MOBJ_ISSHALL               = $countconst++ ;
$MOBJ_SELFLINK              = $countconst++ ;
$MOBJ_FLOWSTOSAMEMOD        = $countconst++ ;
$MOBJ_FLOWDOWNSIN           = $countconst++ ;
$MOBJ_FLOWDOWNSOUT          = $countconst++ ;
$MOBJ_FLOWDOWNSINSKIPLEVEL  = $countconst++ ;
$MOBJ_FLOWDOWNSOUTSKIPLEVEL = $countconst++ ;
$MOBJ_VAMLINKS              = $countconst++ ;
$MOBJ_LAST                  = $countconst-1 ;    # SHOULD BE A BETTER WAY

# module-level stats
$countconst                 = 0 ;
$MMOD_OBJECTS               = $countconst++ ;
$MMOD_HEADINGS              = $countconst++ ;
$MMOD_TABLECELLS            = $countconst++ ;
$MMOD_SHALLS                = $countconst++ ;
$MMOD_SHALLSIN3             = $countconst++ ;
$MMOD_SELFLINKS             = $countconst++ ;
$MMOD_FLOWSTOSAMEMOD        = $countconst++ ;
$MMOD_FLOWDOWNSIN           = $countconst++ ;
$MMOD_FLOWDOWNSOUT          = $countconst++ ;
$MMOD_FLOWDOWNSINSKIPLEVEL  = $countconst++ ;
$MMOD_FLOWDOWNSOUTSKIPLEVEL = $countconst++ ;
$MMOD_3SHALLSLINKEDUP       = $countconst++ ;
$MMOD_3SHALLSLINKEDDOWN     = $countconst++ ;
$MMOD_VAMLINKS              = $countconst++ ;
$MMOD_MINDATE               = $countconst++ ;
$MMOD_AVGDATE               = $countconst++ ;
$MMOD_MAXDATE               = $countconst++ ;
$MMOD_LAST                  = $countconst-1 ;    # SHOULD BE A BETTER WAY

@modheaders = (
        "# Objects",
        "# Headings",
        "# Table Cells",
        "# Shalls",
        "# Shalls in Sec 3", 
        "# Links to self",
        "# Links within module",
        "# Parents (outlinks)",
        "# Children (inlinks)",
        "# Parents, skipping level",
        "# Children, skipping level",
        "# Shalls in Sec 3 with Parents",
        "# Shalls in Sec 3 with Children",
        "# Links from VAM",
        "Oldest modify date",
        "Average modify date",
        "Youngest modify date",
) ;

# takes reference to MDB array and recordstring
# we assume, for now, that the recordstring is very simple csv, no 
# quotes or anything 
sub splitmdbrecord # ($nodearrayref, $recordstring)
{
  my ($nmref, $recordstring) = @_ ;
  my ($moddate, $moddatetype, $objnum, $isheading, $isTableHeader,
      $isTableRow, $isTableCell, $isTablePart, $isshall) 
	= split ',', $recordstring ;

# print "recordstring = $recordstring\n" ;
# object-level stats
  $nmref->[$MOBJ_ISHEADING]     = 0 ;
  $nmref->[$MOBJ_ISTABLEHEADER] = 0 ;
  $nmref->[$MOBJ_ISTABLEROW]    = 0 ;
  $nmref->[$MOBJ_ISTABLECELL]   = 0 ; 
  $nmref->[$MOBJ_ISTABLEPART]   = 0 ;
  $nmref->[$MOBJ_ISSHALL]       = 0 ;
  $nmref->[$MOBJ_MODDATE]     = $moddate ;
  $nmref->[$MOBJ_MODDATEINT]  = $moddate ;
  $nmref->[$MOBJ_MODDATETYPE] = $moddatetype ;
  $nmref->[$MOBJ_OBJNUM]      = $objnum ;
  $nmref->[$MOBJ_ISHEADING]++     if $isheading ;
  $nmref->[$MOBJ_ISTABLEHEADER]++ if $isTableHeader ;
  $nmref->[$MOBJ_ISTABLEROW]++    if $isTableRow ;
  $nmref->[$MOBJ_ISTABLECELL]++   if $isTableCell ; 
  $nmref->[$MOBJ_ISTABLEPART]++   if $isTablePart ;
  $nmref->[$MOBJ_ISSHALL]++       if $isshall ;

  ######################################################################
  # Now take a look at moddate to get an age. We let calling program   #
  # decide what to do about moddatetype                                #
  ######################################################################
  # format: '2007-10-08 07:24:14'
  my $timeofobj ;
  if ($moddate =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/)
  {
    my ($year,$month,$dom,$hour,$min,$sec) = ($1, $2, $3, $4, $5, $6) ;
    $timeofobj = timelocal ($sec, $min, $hour, $dom, $month-1, $year-1900) ;
  }
  else
  {
    warn "COULDN'T PARSE '$moddate'\n" ;
  }
  $nmref->[$MOBJ_MODDATEINT] = $timeofobj ;
}


########################################################################
# SEEMS TO BE UNUSED                                                   #
########################################################################
#sub addobjmetric # ($objpath, $id, $val)
#{
#  my ($objpath, $id, $val) = @_ ;
#  # check id - in range
#  die "addobjmetric: id=$id out of range (0..$MOBJ_LAST)\n"
#      if $id < 0 or $id > MOBJ_LAST ;
#  if (!exists $objmetrics{$objpath}) 
#  {
#    $objmetrics{$objpath} = [] ;
#  }
#  $ref = $objmetrics{$objpath} ;
#  $ref->[$id] = $val ;
## do we want to return something?
#}

1;

