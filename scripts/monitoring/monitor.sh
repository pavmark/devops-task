#!/bin/bash

##VPS Load
cpuUti=$( mpstat 1 1 | tail -n 1 | awk '{ print 100-$12}' )
memoryUti=$( free -m | grep "Mem" | awk '{ print ($3 / $2)*100 }' )

echo "Server: $( hostname ), CPU: ${cpuUti}%, Memory: ${memoryUti}%"

#Container Load
containerStats=$( docker stats --no-stream | tail -n+2 )
IFS=$'\n'
for container in ${containerStats}
do

echo ${container} | awk '{print "Container: " $2, "CPU: " $3, "Memory: " $7 }'

done

#Nginx stub status

for nginxPort in 8081 8082
do

nginxCurl=$( curl -s -D - http://127.0.0.1:${nginxPort}/stub_status | tr -d '\r' )
nginxHeaders=$( echo "${nginxCurl}" | awk -v 'RS=\n\n' '1;{exit}' | tr '\n' ' '  | tr -d ',' )
nginxReadWrite=$( echo "${nginxCurl}" | grep "Reading" )
echo "Nginx on port: ${nginxPort}, Request headers: ${nginxHeaders}, Stub Re/Wr/Wa: ${nginxReadWrite}"
done