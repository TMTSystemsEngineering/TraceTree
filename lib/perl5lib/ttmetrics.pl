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
sub makemdbrecord # ($moddate,$onum,$projid,$isshall,$isdeleted,$hastbx)
{
    my ($moddate,$onum,$projid,$isshall,$isdeleted,$hastbx) = @_ ;
    # this assumes no commas in the values!  should be OK...
    my $mdbrecord = "$moddate,$onum,$projid,$isshall,$isdeleted,$hastbx" ;
print "mdbrecord = '$mdbrecord'\n" ;
    return $mdbrecord ;
}

########################################################################
# getnodedata should return a hash with all the node-specific data in  #
# it, whether straight from the database or derived                    #
########################################################################
# data node keys:
# DIRECT as calculated by xxmlobjtxt
#    MODDATE     modification date
#    ONUM        object number
#    PROJID      project id as opposed to DOORS id
#    ISSHALL     has a "shall" in the text
#    ISDELETED   is deleted: text starts with "Deleted:"
#    HASTBX      has TBD or TBC or TBS in the text, as a word
# DERIVED
#    ISREQUIREMENT  is in section 3 or above, 
#                   is not deleted, has projid not blank
#    LINK_TO_SAME_MOD
#    ERROR_LINK_TO_SELF
#    CHILD_IS_DRDIRD
#    CHILD_IS_REQT
#    ERROR_ICD_ICD_LINK
#    ERROR_NO_STYPE
#    ERROR_NO_TTYPE
#    ERROR_REQT_VA_LINK
#    ERROR_VA_VA_LINK
#    ERROR_WRONG_WAY_VLINK
#    PARENT_IS_DRDICD
#    PARENT_IS_REQT
#    VA_VERIFIES_DRDIRD
#    VA_VERIFIES_REQT

sub getnodedata # ($mdbrecord)
{
    my ($mdbrecord) = @_ ;
    my $datahashref = {} ;
    @mdb = split ',', $mdbrecord ;
    
    # DIRECT
    $datahashref->{"MODDATE"}   = $mdb[0] ;
    $datahashref->{"ONUM"}      = $mdb[1] ;
    $datahashref->{"PROJID"}    = $mdb[2] ;
    $datahashref->{"ISSHALL"}   = $mdb[3] ;
    $datahashref->{"ISDELETED"} = $mdb[4] ;
    $datahashref->{"HASTBX"}    = $mdb[5] ;
print ("gnd: moddate   = " . $datahashref->{"MODDATE"} . "\n" ;
print ("        onum   = " . $datahashref->{"ONUM"}    . "\n" ;
print ("      projid   = " . $datahashref->{"PROJID"}    . "\n" ;
print ("       shall   = " . $datahashref->{"ISSHALL"}   . "\n" ;
print ("     deleted   = " . $datahashref->{"ISDELETED"}  . "\n" ;
print ("      hsttbx   = " . $datahashref->{"HASTBX"}     . "\n" ;
    # DERIVED
    ($objsectionnum = $datahashref->{"ONUM"}) =~ s/\..*$// ;
    $isin3orabove = $objsectionnum >= 3 ;
print "   objsectionnum = $objsectionnum\n" ;
print "   isin3orabove  = $isin3orabove\n" ;
    $datahashref->{"ISREQUIREMENT"} = 
            (   
                $isin3orabove 
            and (not $datahashref->{"ISDELETED"})
            and ($datahashref->{"PROJID"})
            );
print ("      isreqt   = " . $datahashref->{"ISREQUIREMENT"}     . "\n" ;

    return $datahashref ;
}

sub getModnameOnly # (module or node path)
{
    my ($modpath) = @_ ;
    # get rid of everything but the modname itself.
    $modpath =~ s/\/\d+$// ;  # gets rid of node number if any
    $modpath =~ s/^.*\/// ; # gets rid of anything up to a slash, leaving just the name
    return $modpath ;
}

########################################################################
# these test routines are here to encapsulate more complicated         #
# situations if they arise                                             #
########################################################################
sub modIsDRD # (modname or nodepath)
{
    my ($modpath) = @_ ;
    my $modname = getModnameOnly($modpath) ;
    return $modname =~ /^DRD_/ or $modname eq "Science_Cases" ;
}
sub modIsICD # (modname or nodepath)
{;
    my ($modpath) = @_ ;
    my $modname = getModnameOnly($modpath) ;
    return $modname =~ /^ICD_/ ;
}
sub modIsVAM # (modname or nodepath)
{
    my ($modpath) = @_ ;
    my $modname = getModnameOnly($modpath) ;
    return $modname =~ /^VAM_/ ;
}

# Inefficient way to get type booleans all at once.  But more efficient than 
# call modIsDRD etc.
sub getModTypeBooleans # (modname or nodepath)
{
    my ($modpath) = @_ ;
    my $modname = getModnameOnly($modpath) ;
    my ($isDRD, $isICD, $isVAM) ;
    $isDRD = $modname =~ /^DRD_/ or $modname eq "Science_Cases" ;
    $isICD = $modname =~ /^ICD_/ ;
    $isVAM = $modname =~ /^VAM_/ ;
    return ($isDRD, $isICD, $isVAM) ;
}
    
1;
