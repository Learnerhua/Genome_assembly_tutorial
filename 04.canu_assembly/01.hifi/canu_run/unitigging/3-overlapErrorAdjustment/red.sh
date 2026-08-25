#!/bin/sh



#  Paths to things we run.

bin="${DATA_ROOT}/Download/canu-2.3/bin"

pn=/usr/bin/perl
pe=`command -v $pn`
pv=`command    $pn --version | grep version`

jn=java
je=`command -v $jn`
jv=`command    $jn -showversion 2>&1 | head -n 1`

cn=${DATA_ROOT}/Download/canu-2.3/bin/canu
ce=`command -v $cn`
cv=`command    $cn -version`

#  Report paths.

echo ""
echo "Found perl (from '$pn'):"
echo "  $pe"
echo "  $pv"
echo ""
echo "Found java (from '$jn'):"
echo "  $je"
echo "  $jv"
echo ""
echo "Found canu (from '$cn'):"
echo "  $ce"
echo "  $cv"
echo ""

#  Environment for any object storage.

export CANU_OBJECT_STORE_CLIENT=
export CANU_OBJECT_STORE_CLIENT_UA=
export CANU_OBJECT_STORE_CLIENT_DA=
export CANU_OBJECT_STORE_NAMESPACE=
export CANU_OBJECT_STORE_PROJECT=



#  Discover the job ID to run, from either a grid environment variable and a
#  command line offset, or directly from the command line.
#
if [ x$CANU_LOCAL_JOB_ID = x -o x$CANU_LOCAL_JOB_ID = xundefined -o x$CANU_LOCAL_JOB_ID = x0 ]; then
  baseid=$1
  offset=0
else
  baseid=$CANU_LOCAL_JOB_ID
  offset=$1
fi
if [ x$offset = x ]; then
  offset=0
fi
if [ x$baseid = x ]; then
  echo Error: I need CANU_LOCAL_JOB_ID set, or a job index on the command line.
  exit
fi
jobid=`expr -- $baseid + $offset`
if [ x$baseid = x0 ]; then
  echo Error: jobid 0 is invalid\; I need CANU_LOCAL_JOB_ID set, or a job index on the command line.
  exit
fi
if [ x$CANU_LOCAL_JOB_ID = x ]; then
  echo Running job $jobid based on command line options.
else
  echo Running job $jobid based on CANU_LOCAL_JOB_ID=$CANU_LOCAL_JOB_ID and offset=$offset.
fi

if [ $jobid = 1 ] ; then
  minid=1
  maxid=20454
fi
if [ $jobid = 2 ] ; then
  minid=20455
  maxid=40860
fi
if [ $jobid = 3 ] ; then
  minid=40861
  maxid=61265
fi
if [ $jobid = 4 ] ; then
  minid=61266
  maxid=81649
fi
if [ $jobid = 5 ] ; then
  minid=81650
  maxid=102107
fi
if [ $jobid = 6 ] ; then
  minid=102108
  maxid=112452
fi
jobid=`printf %05d $jobid`

if [ -e ./$jobid.red ] ; then
  echo Job previously completed successfully.
  exit
fi

$bin/findErrors \
  -S ../../scer.seqStore \
  -O ../scer.ovlStore \
  -R $minid $maxid \
  -e 0.01 \
  -l 500 \
  -m 0.003 \
  -s \
  -p 5 \
  -o ./$jobid.red.WORKING \
  -t 4 \
&& \
mv ./$jobid.red.WORKING ./$jobid.red


