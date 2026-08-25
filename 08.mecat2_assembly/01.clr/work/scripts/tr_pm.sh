#!/bin/bash

export PATH=${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin/mecat2map -skip_overhang -num_threads 48 -db_dir ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/2-trim_bases/trim_pm_dir -keep_db -task pm -outfmt m4x -out ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/2-trim_bases/trim_pm_dir/trim_pm.m4x ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_final.fasta ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/1-consensus/cns_final.fasta
  temp_result=$?
  if [ $retVal -eq 0 ]; then
    retVal=$temp_result
  fi
fi

echo $retVal > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/scripts/tr_pm.sh.done
