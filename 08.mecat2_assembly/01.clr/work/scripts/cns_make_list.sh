#!/bin/bash

export PATH=${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ls ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_cns_dir/p*.cns.fasta > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_reads_list.txt
  temp_result=$?
  if [ $retVal -eq 0 ]; then
    retVal=$temp_result
  fi
fi

echo $retVal > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/scripts/cns_make_list.sh.done
