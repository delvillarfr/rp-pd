#!/usr/bin/env bash

WORKINGDIR='/Users/iorch/mxabierto/rp-pd'
CURRENT_DATA=${WORKINGDIR}'/current'
TEMPORARY=${WORKINGDIR}'/tmp'
DOWNLOADED=${WORKINGDIR}'/datasets'
RDATA='/Users/iorch/mxabierto/DashboardProsperaDigital/data'
RSCRIPTS='/Users/iorch/mxabierto/DashboardProsperaDigital/crons'


if [ -f ${CURRENT_DATA}/messages.csv ]; then
m_date=`head -2 ${CURRENT_DATA}/messages.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"201[6-9]-"){print i} } }'|tail -1`
AFTER_MESSAGES=`head -2 ${CURRENT_DATA}/messages.csv | awk -F, -v mon="$m_date" '{print $mon}' | tail -n 1`
echo ${AFTER_MESSAGES}
fi
if [ -f ${CURRENT_DATA}/flows.csv ]; then
f_date=`head -2 ${CURRENT_DATA}/flows.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"201[6-9]-"){print i} } }'|tail -1`
AFTER_FLOWS=`head -2 ${CURRENT_DATA}/flows.csv | awk -F, -v mon="$f_date" '{print $mon}' | tail -n 1`
echo ${AFTER_FLOWS}
fi
if [ -f ${CURRENT_DATA}/runs.csv ]; then
r_date=`head -2 ${CURRENT_DATA}/runs.csv|awk -F, '{for(i=1;i<=NF;i++){ if($i~"201[6-9]-"){print i} } }'|tail -1`
AFTER_RUNS=`head -2 ${CURRENT_DATA}/runs.csv|awk -F, -v mon="$r_date" '{print $mon}'|tail -n 1`
echo ${AFTER_RUNS}
fi


python ./run.py m=${AFTER_MESSAGES} f=${AFTER_FLOWS} r=${AFTER_RUNS}
echo 'query finished'

cp ${DOWNLOADED}/contacts.csv ${CURRENT_DATA}/contacts.csv
echo 'contacs done'

if [ ! -f ${CURRENT_DATA}/messages.csv ]; then
cp ${DOWNLOADED}/messages.csv ${CURRENT_DATA}/messages.csv
else
LINES_MESSAGES=$(( `wc -l < ${CURRENT_DATA}/messages.csv`-1 ))
NFIELDS=`head -1 ${DOWNLOADED}/messages.csv| awk -F, '{print NF}'`
if [ ${NFIELDS} -eq 15 ]; then
awk -F, '{print $1","$2","$3","$4","$5","$6","$7","$10","$11","$12","$13","$14","$15}' ${DOWNLOADED}/messages.csv | \
    > ${TEMPORARY}/messages.csv
echo 15
head -1 ${TEMPORARY}/messages.csv
elif [ ${NFIELDS} -eq 14 ]; then
awk -F, '{print $1","$2","$3","$4","$5","$6","$7","$9","$10","$11","$12","$13","$14"}' ${DOWNLOADED}/messages.csv | \
    > ${TEMPORARY}/messages.csv
head -1 ${TEMPORARY}/messages.csv
else
cp ${DOWNLOADED}/messages.csv ${TEMPORARY}/messages.csv
head -1 ${TEMPORARY}/messages.csv
fi
cat ${CURRENT_DATA}/messages.csv | tail -n ${LINES_MESSAGES} >> ${TEMPORARY}/messages.csv
mv ${TEMPORARY}/messages.csv  ${CURRENT_DATA}/messages.csv
fi
echo 'messages done'

if [ ! -f ${CURRENT_DATA}/flows.csv ]; then
cp ${DOWNLOADED}/flows.csv ${CURRENT_DATA}/flows.csv
else
LINES_FLOWS=$(( `wc -l < ${CURRENT_DATA}/flows.csv`-1 ))
cp ${DOWNLOADED}/flows.csv ${TEMPORARY}/flows.csv
cat ${CURRENT_DATA}/flows.csv | tail -n ${LINES_FLOWS} >> ${TEMPORARY}/flows.csv
mv ${TEMPORARY}/flows.csv  ${CURRENT_DATA}/flows.csv
fi
echo 'flows done'

if [ ! -f ${CURRENT_DATA}/runs.csv ]; then
cp ${DOWNLOADED}/runs.csv ${CURRENT_DATA}/runs.csv
else
LINES_RUNS=$(( `wc -l < ${CURRENT_DATA}/runs.csv`-1 ))
cp ${DOWNLOADED}/runs.csv ${TEMPORARY}/runs.csv
cat ${CURRENT_DATA}/runs.csv | tail -n ${LINES_RUNS} >> ${TEMPORARY}/runs.csv
head -1 ${TEMPORARY}/runs.csv > ${CURRENT_DATA}/runs.csv
mv ${TEMPORARY}/runs.csv  ${CURRENT_DATA}/runs.csv
fi
echo 'runs done'

cp ${CURRENT_DATA}/*.csv ${RDATA}/

cd ${RSCRIPTS}

./runs.R
./contacts.R
./zipruns.R
./Mapa.R
./pre_pars.R


