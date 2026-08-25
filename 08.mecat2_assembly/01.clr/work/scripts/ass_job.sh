#!/bin/bash

export PATH=${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin:$PATH
retVal=0
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin/fsa_ol_filter ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/3-assembly/asm_pm.m4 ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/4-fsa/filter.m4 --thread_size=48 --output_directory=${REPO_ROOT}/08.mecat2_assembly/01.clr/work/4-fsa --max_overhang=-1 --min_identity=-1 --genome_size=12m
  temp_result=$?
  if [ $retVal -eq 0 ]; then
    retVal=$temp_result
  fi
fi
if [ $retVal -eq 0 ]; then
  ${DATA_ROOT}/Download/MECAT2/Linux-amd64/bin/fsa_assemble ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/4-fsa/filter.m4 --read_file=${REPO_ROOT}/08.mecat2_assembly/01.clr/work/2-trim_bases/trimReads.fasta --thread_size=48 --output_directory=${REPO_ROOT}/08.mecat2_assembly/01.clr/work/4-fsa 
  temp_result=$?
  if [ $retVal -eq 0 ]; then
    retVal=$temp_result
  fi
fi

echo $retVal > ${REPO_ROOT}/08.mecat2_assembly/01.clr/work/scripts/ass_job.sh.done
