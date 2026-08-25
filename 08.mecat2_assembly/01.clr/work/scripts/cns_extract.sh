#!/bin/bash

export PATH=${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin/mecat2extseqs 12m 30 ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_reads_list.txt > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_final.fasta
  temp_result=$?
  if [ $retVal -eq 0 ]; then
    retVal=$temp_result
  fi
fi

echo $retVal > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/scripts/cns_extract.sh.done
