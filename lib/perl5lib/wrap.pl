
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
# Subroutine wrap ($lines, $maxlen, $indent1, $indentn) `wrap' takes as 
# input lines of text ($lines) and re-formats them to fit within a 
# maximum length ($maxlen), which includes optional indentation 
# specified as parameters to the call.  The indentation is specified 
# separately for the first line ($indent1) of each paragraph and for the 
# rest of the resulting lines for each paragraph.  The indentation is 
# included within the character count determining the length of the 
# line. 

# NOTE: `wrap' takes as input a scalar containing the entire text to be 
# wrapped.  It does _not_ take a PERL list of paragraphs.  Similarly, 
# output is in the form of a scalar containing the entire wrapped text. 

# Paragraphs are delimited on both input and output by double new-lines.  
# If you want some other behavior, you'll need to call wrap individually 
# for each paragraph.  Multiple new-lines are preserved with the same 
# number of new-lines. 

# If the max number of charcters per line ($maxlen) is specified as 0, 
# each paragraph is concatenated into a single long line.  This can be 
# useful for preparing ascii text for insertion into a word processor. 

# Because extra white space in the input lines is eliminated, we handle 
# tab characters by default.  Tabs in the indentation parameters are 
# retained. 

require "miscutils.pl" ;

sub wrap  
{
  my ($lines, $maxlen, $indent1, $indentn) = @_ ;
  my ( $indent1tabs, $indentntabs, $line, $outlen, $outline, 
          $outlineIsEmpty, $outlines, $spacelen, $spaces, $word, $wordlen) ;
  my (@line, @lines) ;

  # First we take a look at the desired indentation to see whether 
  # there're any tabs in it.  If there are, we convert them to spaces 
  # now.  Later, the tab version will be substituted back into the 
  # output lines. 

  if ($indent1 =~ /\t/)
  {
    $indent1tabs = $indent1 ;
    $indent1 = tabexpand ($indent1) ;
  }
  if ($indentn =~ /\t/)
  {
    $indentntabs = $indentn ;
    $indentn = tabexpand ($indentn) ;
  }

  # Now we start on the input data.  First do a series of substitutions 
  # to handle funny stuff. 

  $lines =~ s/\.  /\024/g ;    #! period-space-space     -> ^x 
  $lines =~ s/\n\n/\025/mg ;   #! double newlines        -> ^y 
  $lines =~ s/\025\n/\026/mg ; #! odd number of newlines -> ^z 

  $lines =~ s/\s+/ /mg ;       # all remaining whitespace to space 
  $lines =~ s/([\024-\026]) /$1/mg ;  # eliminate single space after 
                                      # newlines or '.  ' 
  $lines =~ s/^ // ;                  # eliminate single space at very 
                                      # beginning. 

  # now go back 
  $lines =~ s/\024/.  /mg ;    # re-insert period-space-space
  $lines =~ s/\025/\n\n/mg ;   # re-insert double new-lines
  $lines =~ s/\026/\n\n\n/mg ; # re-insert odd number new-lines

  # Seems we'll get an empty line on the end if there's a newline on 
  # the end. 
  @lines = split /\n/, $lines, -1 ;  # perl split wants a negative 
                                     # number for its limit if it isn't 
                                     # to strip off trailing null 
                                     # fields. 

  $outlines = '' ;

  # At this point, each $line[] results in an output line, at least, so 
  # we can close off each output paragraph with each iteration of 
  # following loop.  We also know all white space has been reduced to 
  # single spaces or period-space-space. 

  # We need to decide how (or whether) to preserve remaining spacing. 

  while (@lines)
  {
    $line = shift @lines ;

    $outline = $indent1 ;  # concatenate to output 
    $outlineIsEmpty++ ;    # need this to test each output line 

    while ($line)
    {
      # We process a word at a time.  This isn't the most efficient, 
      # but it is the simplest and least apt to error. 

      $line =~ s/^([^ ]+)// ;
      $word = $1 ;
      $wordlen = length $word ;
      if ($line =~ s/^( +)//)
      {
	$spaces = $1 ;
      }
      else
      {
	$spaces = '' ;
      }

      $spacelen = length $spaces ;

      $outlen = length $outline ;

      #! Three cases: 
      #!   1) Word fits: add it in ; 
      #!   2) Word doesn't fit and outline has something: finish off 
      #!      outline and start a new one; and 
      #!   3) Word doesn't fit but outline's empty: add the word and
      #!      finish off line and start a new one.

      # Remember that if $maxlen == 0 the word fits by definition.
      if (!$maxlen or $outlen + $wordlen <= $maxlen)  # don't test 
                                                      # counting end 
                                                      # space 
      {
	$outline .= $word . $spaces ;
	$outlen += $wordlen + $spacelen ;  # but keep track of end space 
	$outlineIsEmpty = 0 ;
      }
      elsif (! $outlineIsEmpty)   # case two : finish off outline ; 
      {
	$outlines .= $outline . "\n" ;
	$outline = $indentn . $word .$spaces ;   # normal indent 
      }
      else      # case three - have to put the word on a line by itself 
      {
	$outlines .= $word . $spaces . "\n" ;
	$outlineIsEmpty++ ;
	$outline = $indentn ;   # normal indent 
      }
    }

    # There's probably something in $outline still, because we exited 
    # the loop when $line was empty, but before $outline was added in. 
    # We also have to add another newline, because we chopped it off at 
    # the split before the loop. 

    $outlines .= $outline . "\n" ;
  }

  # Now, if the original indents contained tabs, put the back by simple 
  # substitution. 

  $outlines =~ s/^$indent1/$indent1tabs/mg if (defined $indent1tabs) ;
  $outlines =~ s/^$indentn/$indentntabs/mg if (defined $indentntabs) ;

  return $outlines ;
}

1;
