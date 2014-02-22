import os
import re
import csv

preschoolids= csv.reader(open('/home/shivangi/src/reports/angschoolcount.csv','r'),delimiter='|')
postschoolids= csv.reader(open('/home/shivangi/src/assessments/scripts/angfiles.csv','r'),delimiter=',')

prenotpost= open("/home/shivangi/src/assessments/scripts/prenotpostang.csv",'wb')
postnotpre= open("/home/shivangi/src/assessments/scripts/postnotpreang.csv",'wb')

def getRow(row):
  line = str(row).strip('[')
  line = line.strip(']')
  return line

classids={}

for row in postschoolids:
    schoolid=row[0].strip()
    classids[schoolid]=0

for row in preschoolids:
    schoolid=row[3].strip()
    if schoolid in classids:
      classids[schoolid]=1
    else:
      prenotpost.write(str(schoolid)+",")
  
for id in classids:
  if classids[id]==0:
    postnotpre.write(str(id)+",")
  
