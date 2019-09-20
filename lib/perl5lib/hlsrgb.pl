
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
 #####################################################################
 # Compute RGB from HLS. The l and s are between [0,1] and h is      #
 # between [0,360]. The returned r,g,b triplet is between [0,1].     #
 #####################################################################
sub hls2rgb # (h, l, s)
{

   my ($h, $l, $s) = @_ ;
   my ($m1, $m2) ;
   my ($r, $g, $b) ;
   # normalize
   $h += 360.0 while $h < 0.0 ; $h -= 360.0 while $h >= 360.0 ;
   $l = 0.0 if $l < 0.0 ; $l = 1.0 if $l > 1.0 ;
   $s = 0.0 if $s < 0.0 ; $s = 1.0 if $s > 1.0 ;

   if ($l <= 0.5) { $m2 = $l*(1.0 + $s); }
   else           { $m2 = $l + $s - $l*$s; }
   $m1 = 2.0*$l - $m2;

   if ($s == 0.0) { $r = $l; $g = $l; $b = $l; }
   else
   {
     $r = HLStoRGB1($m1, $m2, $h+120);
     $g = HLStoRGB1($m1, $m2, $h);
     $b = HLStoRGB1($m1, $m2, $h-120);
   }
   return ($r, $g, $b) ;
}

#______________________________________________________________________________
sub HLStoRGB1 # ($m1, double $m2, double $h)
{
   # Auxiliary to HLS2RGB().
   my ($m1, $m2, $h) = @_ ;

   if ($h > 360) { $h = $h - 360; }
   if ($h < 0)   { $h = $h + 360; }
   if ($h < 60 ) { return $m1 + ($m2-$m1)*$h/60; }
   if ($h < 180) { return $m2; }
   if ($h < 240) { return $m1 + ($m2-$m1)*(240-$h)/60; }
   return $m1;
}


# Compute HLS from RGB. The r,g,b triplet is between [0,1], hue is between [0,360], light and saturation are [0,1].
sub rgb2hls # (r, g, b)
{
   my ($r, $g, $b) = @_ ;
   my ($rnorm, $gnorm, $bnorm, $minval, $maxval, $msum, $mdiff) ;
   my ($h, $l, $s) ;

   # constrain
   $r = 0.0 if $r < 0.0 ; $r = 1.0 if $r > 1.0 ;
   $g = 0.0 if $g < 0.0 ; $g = 1.0 if $g > 1.0 ;
   $b = 0.0 if $b < 0.0 ; $b = 1.0 if $b > 1.0 ;

   $minval = $maxval = $g ;
   $minval = $r if $r < $g ; $minval = $b if $b < $minval ;
   $maxval = $r if $r > $g ; $maxval = $b if $b > $maxval ;

   $rnorm = $gnorm = $bnorm = 0.0;
   $mdiff = $maxval - $minval;
   $msum  = $maxval + $minval;
   $l = 0.5 * $msum;

   if ($maxval != $minval) 
   {
      $rnorm = ($maxval - $r)/$mdiff;
      $gnorm = ($maxval - $g)/$mdiff;
      $bnorm = ($maxval - $b)/$mdiff;
   } 
   else 
   {
      return (0.0, $l, 0.0) ;
   }

   if ($l < 0.5) { $s = $mdiff/$msum; }
   else          { $s = $mdiff/(2.0 - $msum); }

   if    ($r == $maxval) { $h = 60.0 * (6.0 + $bnorm - $gnorm); }
   elsif ($g == $maxval) { $h = 60.0 * (2.0 + $rnorm - $bnorm); }
   else                  { $h = 60.0 * (4.0 + $gnorm - $rnorm); }

   if ($h > 360) { $h = $h - 360; }

  return ($h, $l, $s) ;
}

1;

