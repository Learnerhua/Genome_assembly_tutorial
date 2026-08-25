#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/filter_m4 ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/pac_reads ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/contig_tiles ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/rd2ctg.m4 ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/rd2ctg_filtered.m4
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
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/pm4 ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/pac_contigs ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/rd2ctg_filtered.m4
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
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/ctgcns ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/pac_reads ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/pac_contigs 48 ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/polished_contigs.fasta
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/plctg1_cns.sh.done
