#!/bin/bash

export PATH=${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:${DATA_ROOT}/Download/NECAT/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/fsa_ol_filter ${REPO_ROOT}/09.necat_assembly/01.ont/work/3-assembly/pm.m4.gz ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/filter.m4 --thread_size=48 --output_directory=${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa  --genome_size=12157246

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
  ${DATA_ROOT}/Download/NECAT/Linux-amd64/bin/fsa_assemble ${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa/filter.m4 --read_file=${REPO_ROOT}/09.necat_assembly/01.ont/work/trimReads.fasta.gz --thread_size=48 --output_directory=${REPO_ROOT}/09.necat_assembly/01.ont/work/4-fsa 
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

echo $retVal > ${REPO_ROOT}/09.necat_assembly/01.ont/work/scripts/ass_job.sh.done
