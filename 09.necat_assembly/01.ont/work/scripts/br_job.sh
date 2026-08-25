#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/fsa_ctg_bridge  ${REPO_ROOT}/09.necat_assembly/01.ont/work/1-consensus/raw_reads/raw_read_list.txt ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/contigs.fasta ${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/rawread2ctg.m4a.gz ${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs/bridged_contigs.fasta --readinfo_fname=${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/readinfos.gz --ctg2ctg_file=${REPO_ROOT}/09.necat_assembly/01.ont/work/5-align_contigs/ctg2ctg.m4a.gz  --thread_size=48 --output_directory=${REPO_ROOT}/09.necat_assembly/01.ont/work/6-bridge_contigs 
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/br_job.sh.done
