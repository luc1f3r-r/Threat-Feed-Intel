#!/bin/bash

# This script is executed by cron daemon on a linux machine. It's scheduled to run at 0 0 * * * (every day at 00:00)

echo "Python script executing"
# This line runs a python script located at "/home/jenkins/threat_feed/script.py" using python3 interpreter.
/usr/bin/python3 /home/jenkins/threat_feed/script.py

# Wait for 30 seconds
sleep 30

# Move files with names matching "rhisac_iocs_last*" from the current directory to "/home/jenkins/threat_feed"
mv /home/jenkins/rhisac_iocs_last* /home/jenkins/threat_feed

echo "Appending the new file"
# Append the contents of all files with names matching "rhisac_iocs_last*" in the "/home/jenkins/threat_feed" directory to "/home/jenkins/threat_feed/new_rhisac.csv"
cat /home/jenkins/threat_feed/rhisac_iocs_last* >> /home/jenkins/threat_feed/new_rhisac.csv

# Wait for 20 seconds
sleep 20

echo "Removing Duplicates"
# Remove duplicate lines from "/home/jenkins/threat_feed/new_rhisac.csv" and save the result to "/home/jenkins/threat_feed/rhisac.csv"
awk '!seen[$0]++ || NR==1' /home/jenkins/threat_feed/new_rhisac.csv > /home/jenkins/threat_feed/rhisac.csv
#sort -t, -k1,1 -u /home/jenkins/threat_feed/rhisac.csv > /home/jenkins/threat_feed/rhisac.csv

#echo "Adding the new column"
#sed -i '1i ioc_value,ioc_indicatorType,ioc_firstSeen,ioc_lastSeen,ioc_value_list' /home/jenkins/threat_feed/rhisac.csv


# Wait for 20 seconds
sleep 20

echo "Uploading the updated file to S3 Bucket"
# Upload the file "/home/jenkins/threat_feed/rhisac.csv" to an S3 bucket with the name "rhisac-intel-feed"
/usr/local/bin/aws s3 cp /home/jenkins/threat_feed/rhisac.csv s3://rhisac-intel-feed/

# Wait for 10 seconds
sleep 10

echo "Removing additional files"
# Remove the file "/home/jenkins/threat_feed/new_rhisac.csv"
rm /home/jenkins/threat_feed/new_rhisac.csv

echo "Cleaning up the Folder"
# Move files with names matching "rhisac_iocs_last*" from "/home/jenkins/threat_feed" to "/home/jenkins/RHISAC"
mv /home/jenkins/threat_feed/rhisac_iocs_last* /home/jenkins/RHISAC

echo "Task completed!"
