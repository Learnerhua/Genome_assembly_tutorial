#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/oc2pmov  -a 1000 -d 0.25 -t 1 -q 500 -z 20 -s 3 -k 15 -b 2000 -m 500 -u 1 -j 0 -n 500 -e 0.5 -i 1 -t 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter2/PackedData 0 ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/cns_iter2/PackedData/pm_result_0
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/cns_2_al_vol_0.sh.done
