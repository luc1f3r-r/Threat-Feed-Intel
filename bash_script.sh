#!/bin/bash

#0 0 * * * /bin/bash bash_script.sh

echo "Python script executing"
/usr/bin/python3 /home/jenkins/threat_feed/script.py

sleep 30

mv /home/jenkins/rhisac_iocs_last* /home/jenkins/threat_feed

echo "Appending the new file"
cat /home/jenkins/threat_feed/rhisac_iocs_last* >> /home/jenkins/threat_feed/new_rhisac.csv

sleep 20

echo "Removing Duplicates"
awk '!seen[$0]++ || NR==1' /home/jenkins/threat_feed/new_rhisac.csv > /home/jenkins/threat_feed/rhisac.csv
#sort -t, -k1,1 -u /home/jenkins/threat_feed/rhisac.csv > /home/jenkins/threat_feed/rhisac.csv

#echo "Adding the new column"
#sed -i '1i ioc_value,ioc_indicatorType,ioc_firstSeen,ioc_lastSeen,ioc_value_list' /home/jenkins/threat_feed/rhisac.csv


sleep 20

echo "Uploading the updated file to S3 Bucket"
/usr/local/bin/aws s3 cp /home/jenkins/threat_feed/rhisac.csv s3://rhisac-intel-feed/

sleep 10

echo "Removing additional files"
rm /home/jenkins/threat_feed/new_rhisac.csv

echo "Cleaning up the Folder"
mv /home/jenkins/threat_feed/rhisac_iocs_last* /home/jenkins/RHISAC

echo "Task completed!"
