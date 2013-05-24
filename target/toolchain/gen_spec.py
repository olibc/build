#!/usr/bin/env python
#

from string import Template
import sys

if len(sys.argv) < 4:
  print "Usage %s <spec_template> <flags_config> <output>" % sys.argv[0]
  exit(1)

specPath = sys.argv[1]
basePath = sys.argv[2]
outputPath = sys.argv[3]

f = open(specPath)
specTemplate = Template(f.read())
f.close()

f = open(basePath + "/gcc_default_cflags")
rawcflags = f.read()
cflags = rawcflags.strip().split(" ")
f.close()

f = open(basePath + "/gcc_default_cxxflags")
rawcppflags = f.read()
cppflags = rawcppflags.strip().split(" ")
f.close()

f = open(basePath + "/gcc_default_ldflags")
rawldflags = f.read()
ldflags = rawldflags.strip().split(" ")
f.close()

def isPreDefMarco(cflag):
   return cflag.startswith("-D") or cflag.startswith("-U")

def isAsmArg(cflag):
   return cflag.startswith("-Wa,")

def isLinkerArg(cflag):
   return cflag.startswith("-Wl,")

def resolveLDOption(ldflag):
  if not ldflag.startswith("-z"):
    return ldflag
  return ldflag.replace(",", " ")

def isPICorPIE(cflag):
  return (cflag == "-fpic" or cflag == "-fPIC" or
          cflag == "-fpie" or cflag == "-pie" or cflag == "-fPIE")

cc1_options = " ".join([cflag for cflag in cflags
                                if not isPreDefMarco(cflag) and
                                   not isAsmArg(cflag) and
                                   not isPICorPIE(cflag)])

cc1plus_options = " ".join([cflag for cflag in (cflags+cppflags)
                                    if not isPreDefMarco(cflag) and
                                       not isAsmArg(cflag) and
                                       not isPICorPIE(cflag)])

link_options = " ".join([resolveLDOption(ldflag[4:]) for ldflag in ldflags
                                                       if isLinkerArg(ldflag)])

asm_options = " ".join([asflag[4:] for asflag in cflags
                                     if isAsmArg(asflag)])

templateArgument = {'cc1_options' : cc1_options,
                    'cc1plus_options' : cc1plus_options,
                    'link_command' : link_options,
                    'asm_options' : asm_options}

f = open(outputPath,"w")
f.write(specTemplate.substitute(templateArgument))
f.close()
