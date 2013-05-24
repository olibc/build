#!/usr/bin/env python
#

from string import Template
import sys

if len(sys.argv) < 4:
  print "Usage %s <wrapper_template> <compilerName> <output>" % sys.argv[0]
  exit(1)

wrapperPath = sys.argv[1]
compilerName = sys.argv[2]
outputPath = sys.argv[3]

f = open(wrapperPath)
specTemplate = Template(f.read())
f.close()

templateArgument = {'compilerName':compilerName}

f = open(outputPath,"w")
f.write(specTemplate.substitute(templateArgument))
f.close()
