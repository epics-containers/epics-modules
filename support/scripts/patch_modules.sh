#!/bin/bash

# Patch StreamDevice
# (see https://raw.githubusercontent.com/EPICS-synApps/support/R6-2/assemble_synApps.sh)
rm StreamDevice*/GNUmakefile
sed -i 's/PCRE=/#PCRE=/g' StreamDevice*/configure/RELEASE
echo "SSCAN=" >> StreamDevice*/configure/RELEASE
echo "STREAM=" >> StreamDevice*/configure/RELEASE
sed -i 's/#PROD_LIBS += sscan/PROD_LIBS += sscan/g'  StreamDevice*/streamApp/Makefile

# Uncomment sseq support in calc
sed -i s:'#SNCSEQ':'SNCSEQ':g calc*/configure/RELEASE

# Enable TIRPC for ASYN (not for RTEMS)
echo "TIRPC=YES" >> asyn*/configure/CONFIG_SITE.Common.linux-x86_64

cd ${SUPPORT}/autosave*
patch -p1 < ${SUPPORT}/scripts/autosave.patch
