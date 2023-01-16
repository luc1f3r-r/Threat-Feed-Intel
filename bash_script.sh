#!/bin/bash

#0 0 * * * /bin/bash bash_script.sh

/usr/bin/python3 /Users/prashantraj/Documents/cron/script.py

sleep 180

existing_file="rhisac.csv"
append_file="rhisac_iocs_last*.csv"

#Check if the appending file exists
if [ -f "$append_file" ]; then
   # Append contents and remove duplicates
   cat $append_file >> $existing_file
   sort -u $existing_file -o $existing_file
   echo "Appended contents of $append_file to $existing_file and removed duplicates"
else
   echo "File $append_file not found"
fi

/usr/local/bin/aws cp /home/jenkins/threat-feed/rhisac.csv s3://rhisac-intel-feed/rhisac.csv

sleep 900

mv /home/jenkins/rhisac_iocs_last*.csv /home/jenkins/RHISAC
