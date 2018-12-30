import os
import glob
from java.io import IOException
from java.io import File
import fnmatch
from java.util.jar import JarFile
from java.util.jar import Manifest
from java.util.jar import Attributes

for args in sys.argv:
   if(args == 'printJarsVersion'):
      printJarsVersion()

def printJarsVersion():
  manifest = getjarsManifestFromDir()
  System.out.println(manifest)
