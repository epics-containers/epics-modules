#!/bin/bash

set -xe

# initialize the global support/configure/RELEASE
python3 module.py init

if [[ ${TARGET_ARCHITECTURE} == "rtems" ]] ; then
    python3 module.py add epics-modules ipac IPAC 2.16
fi

# get basic support modules in order of dependencies
python3 module.py add-tar http://www-csr.bessy.de/control/SoftDist/sequencer/releases/seq-{TAG}.tar.gz seq SNCSEQ 2.2.9 
python3 module.py add epics-modules sscan SSCAN R2-11-5
python3 module.py add epics-modules calc CALC R3-7-4 
python3 module.py add epics-modules asyn ASYN R4-42 
python3 module.py add epics-modules alive ALIVE R1-3-1 
if [[ ${TARGET_ARCHITECTURE} != "rtems" ]] ; then
    python3 module.py add epics-modules autosave AUTOSAVE  R5-10-2 
    python3 module.py add epics-modules busy BUSY R1-7-3 
    python3 module.py add epics-modules iocStats DEVIOCSTATS 3.1.16 
    python3 module.py add paulscherrerinstitute StreamDevice STREAM 2.8.22
fi
python3 module.py add epics-modules std STD R3-6-3

cp scripts/ioc_Makefile_${TARGET_ARCHITECTURE} ../ioc/iocApp/src/Makefile

# patch support modules and fix up all dependencies
echo IOC=${IOC} >> configure/RELEASE 
    bash scripts/patch_modules.sh 
    python3 module.py dependencies