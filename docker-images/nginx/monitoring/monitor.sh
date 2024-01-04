#!/bin/bash

#Container Utilization
cgroupPath="/sys/fs/cgroup/"

initialUsage=$(cat "$cgroupPath/cpu.stat" | grep "usage_usec" | awk '{print $2}')
startTime=$(date +%s.%N)

sleep 1

currentUsage=$(cat "$cgroupPath/cpu.stat" | grep "usage_usec" | awk '{print $2}')
elapsedTime=$(echo "$(date +%s.%N) - $startTime" | bc)
cpuUtilization=$(echo "scale=2; 100 * ($currentUsage - $initialUsage) / ($elapsedTime * 1000000)" | bc)

memoryMax=$( cat $cgroupPath/memory.max )
memoryCurrent=$( cat $cgroupPath/memory.current )

# If there isnt set memory limit use host memory

if [ ${memoryMax} == "max" ]
then
memoryMax=$(cat /proc/meminfo  | grep MemTotal | awk '{print $2}')
fi

memoryUtilization=$( echo "scale=10; 100 * ( ${memoryCurrent} / (${memoryMax} * 1000) )" | bc )
memoryUtilization=$( printf "%.2f\n" ${memoryUtilization} )

echo "Container: $( hostname ), CPU: ${cpuUtilization}%, Memory: ${memoryUtilization}%"

#Nginx stub status

for nginxPort in 8081
do

nginxCurl=$( curl -s -D - http://127.0.0.1:${nginxPort}/stub_status | tr -d '\r' )
nginxHeaders=$( echo "${nginxCurl}" | awk -v 'RS=\n\n' '1;{exit}' | tr '\n' ' '  | tr -d ',' )
nginxReadWrite=$( echo "${nginxCurl}" | grep "Reading" )
echo "Nginx on port: ${nginxPort}, Request headers: ${nginxHeaders}, Stub Re/Wr/Wa: ${nginxReadWrite}"
done