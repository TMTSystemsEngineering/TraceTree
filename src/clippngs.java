/** License Terms
 * 
 * Copyright (c) 2006,2007,2008,2009,2010,2011,2012,2013>, California 
 * Institute of Technology ("Caltech").  U.S. Government sponsorship 
 * acknowledged.
 * 
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without 
 * modification, are permitted provided that the following conditions are 
 * met:
 * 
 * 
 *  *   Redistributions of source code must retain the above copyright 
 *      notice, this list of conditions and the following disclaimer.
 * 
 *  *   Redistributions in binary form must reproduce the above copyright 
 *      notice, this list of conditions and the following disclaimer in the 
 *      documentation and/or other materials provided with the 
 *      distribution.
 * 
 *  *   Neither the name of Caltech nor its operating division, the Jet 
 *      Propulsion Laboratory, nor the names of its contributors may be 
 *      used to endorse or promote products derived from this software 
 *      without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED 
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER 
 * OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
import java.text.*;
import java.util.*;
import java.io.*;
import javax.imageio.* ;
import java.awt.image.* ;
import java.awt.* ;

class PNGFilter implements FilenameFilter
{
  public boolean accept (File f, String fname)
  {
    File ff = new File(fname) ;
    if (ff.isDirectory()) return false ;
    return fname.endsWith(".png") ;
  }
}

public class clippngs {

  public static File[] listFilesAsArray( File directory, FilenameFilter filter, boolean recurse)
  {
    Collection files = listFiles(directory, filter, recurse);
    File[] arr = new File[files.size()];
    return (File [])files.toArray(arr);
  }

  public static Collection listFiles( File directory, FilenameFilter filter, boolean recurse)
  {
    Vector files = new Vector();
    File[] entries = directory.listFiles() ;
    for (int f = 0; f < entries.length; f++) 
    {
      File entry = (File)entries[f] ;

      // If there is no filter or the filter accepts the 
      // file / directory, add it to the list
      if (filter == null || filter.accept(directory, entry.getName()))
      {
	files.add(entry);
      }

      // If the file is a directory and the recurse flag
      // is set, recurse into the directory
      if (recurse && entry.isDirectory())
      {
	files.addAll(listFiles(entry, filter, recurse));
      }
    }

    return files;           
  }

  public static void main(String args[]) 
  {
    PNGFilter pngfilter = new PNGFilter() ;

    String dirname = "." ;
    if (args.length == 1)
    {
      dirname = args[0] ;
    }
    File dir = new File (dirname) ;
    if (!dir.exists() || !dir.isDirectory()) 
    {
      System.err.println ("Directory \"" + dirname + "\" either doesn't exist or isn't a directory, bye.") ;
      System.exit (1) ;
    }

    File[] pnglist = listFilesAsArray(dir, pngfilter, true) ;
    System.out.println ("pnglist.length = " + pnglist.length) ;

    for (int i = 0 ; i < pnglist.length ; i++)
    {
      File f = pnglist[i] ;
      String filename = f.getPath() ;
      BufferedImage bi = null ;
      // System.out.println ("Reading " + filename) ;
      try {
	bi = ImageIO.read(f) ;
      } 
      catch ( java.io.IOException ioe)  { System.err.println ("oops:" + ioe) ; }
      if (bi == null)
      {
	System.err.println ("null buffered image for file " 
	    + filename + ", skipping") ;
	continue ;
      }
      int w = bi.getWidth() ;
      int h = bi.getHeight() ;
      int irgb ;
      int iblack = Color.black.getRGB() ;
      // example System.out.println ("green=" + Color.black.getGreen()) ;
      boolean isallblack = true ;
      // System.out.println ("Checking " + filename 
	         // + " (size=" + w + "x" + h + ")") ;
      if (w == 1 || h == 1) 
      {
	System.out.println (filename 
	       + " (size=" + w + "x" + h + "), too small.") ;
      }
      else
      {
	for (int iw = 0 ; iw < w ; iw++) 
	{
	  for (int ih = 0 ; ih < h ; ih += h-1) 
	  {
	    irgb = bi.getRGB(iw, ih) ;
	    if (irgb != iblack) isallblack = false ;
	      // System.err.println ("Uh oh, irgb=" + irgb + " at " + iw + "," + ih) ;
	  }
	}
	for (int ih = 0 ; ih < h ; ih++) 
	{
	  for (int iw = 0 ; iw < w ; iw += w-1)
	  {
	    irgb = bi.getRGB(iw, ih) ;
	    if (irgb != iblack) isallblack = false ;
	      // System.err.println ("Uh oh, irgb=" + irgb + " at " + iw + "," + ih) ;
	  }
	}
	if (!isallblack)
	  System.out.println (filename 
		   + " (size=" + w + "x" + h + ") is not all black border") ;
	else
	{
	  WritableRaster r = bi.getRaster () ;
	  WritableRaster newr = r.createWritableChild (1, 1, w-2, h-2, 0, 0, null) ;
	  BufferedImage newbi 
	      // = new BufferedImage (w-2, h-2, BufferedImage.TYPE_INT_ARGB) ;
	      = new BufferedImage (bi.getColorModel(), newr, true, null) ;
	  try 
	  {
	    File renamef = new File (filename + ".bak") ;
	    boolean renameok = f.renameTo(renamef) ;
	    if (renameok)
	    {
	      System.out.println (filename 
		   + " (size=" + w + "x" + h + ") clipped") ;
	      File newf = new File(filename) ;
	      ImageIO.write(newbi, "png", newf);
	    }
	    else
	    {
	      System.err.println ("Failed to rename " + filename + " to " + filename + ".bak - skipping write") ;
	    }
	  } 
	  catch (java.io.IOException ioe) 
	  {
	    System.err.println ("UH OH trying to write new file " + filename + ":" + ioe) ; 
	  }

	}
      }
    }
  }
}
