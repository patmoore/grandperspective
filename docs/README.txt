----------------------------------------------------------------------
  GrandPerspective, GRANDPERSPECTIVE_SOFTWARE_VERSION
----------------------------------------------------------------------

* INTRODUCTION

GrandPerspective is a small utility for Mac OS X that can draw two-
dimensional views of disk use within a file system. This can help you
to manage your disk, as you can easily spot which files and folders
take up the most space.

The graphical representation is a logical one, where each file is
shown as a rectangle with an area proportional to the file's size.
Files in the same folder appear together, but other than that the
placement of files is arbitrary. You can observe this by resizing the
view window. The location of files will change, in order to keep the
rectangles as square as possible.


* SYSTEM REQUIREMENTS

- PowerPC processor

  This executable is still built for Macs with a PowerPC processor.
  The source code has already been modified so that it should compile
  and run properly on Intel processors as well (thanks to Craig
  Hughes for his help with this). However, I do not (yet) have the
  software to build Universal Binaries, nor easy access to an Intel
  Mac to actually test it. This makes releasing an "official"
  Universal Binary a bit cumbersome, but expect one soon anyway.

- Mac OS X, 10.2 or higher
  
  Note: The dependency on functionality introduced after Mac OS X 10.0
  is minimal. If you have access to Mac OS X 10.0, feel free to try to 
  make the modifications required to get it to run there. I would 
  gratefully receive any patches. :-)


* CONTENTS

This version of GrandPerspective is released as two separate files:

  * GrandPerspective-GRANDPERSPECTIVE_SOFTWARE_VERSION_ID.dmg
 
      This is the main release file. It contains all you need to run
      the application. To install the application, open the disk 
      image and drag the application icon onto your Applications
      folder, or wher'ever you want to put it onto your file system.
      Next, run the application by clicking on the icon.

  * GrandPerspective-GRANDPERSPECTIVE_SOFTWARE_VERSION_ID-src.tgz

      This contains the source code of the application. It consists of
      the Objective C source code, as well as various auxiliary files,
      such as the nib files that are used to construct the GUI.


* LICENSE

The GrandPerspective application has been released as Open Source 
under the GNU General Public License. See COPYING.txt for details.


* THE WEB SITE

For more information about the application, please visit the website
at http://grandperspectiv.sourceforge.net. From there, you can 
download the latest release of the software. It is also possible to
report bugs, request additional features, or provide more general 
feedback.


* CONTACT DETAILS

The GrandPerspective application has been developed by Erwin Bonsma.
Please visit the website at http://grandperspectiv.sourceforge.net for
details on how to contact me.

