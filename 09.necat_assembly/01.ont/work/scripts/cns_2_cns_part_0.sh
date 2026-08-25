#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2cns -s 0 -t 48 -a 2000 -x 4 -y 12 -l 1000 -e 0.5 -p 0.8 -u 0 -r 1 -f 0 ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter2/PackedData ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter2/cns_candidates.txt ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter2/tmp_cns.fasta_0 ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter2/tmp_raw.fasta_0 -mn 0 1
  temp_result=(${PIPESTATUS[*]})
  for i in ${temp_result[*]} 
  do
    if [ $retVal -eq 0 ]; then
      retVal=$i
    else
      break
    fi
  done
fi

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/cns_2_cns_part_0.sh.done
