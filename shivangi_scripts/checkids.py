import os
import re
import csv

schoolids4= csv.reader(open('/home/shivangi/src/assessments/10on10files4.csv','r'),delimiter=',')
schoolids5= csv.reader(open('/home/shivangi/src/assessments/10on10files5.csv','r'),delimiter=',')

fournot5= open("/home/shivangi/src/assessments/4not510on10.csv",'wb')
fivenot4= open("/home/shivangi/src/assessments/5not410on10.csv",'wb')

def getRow(row):
  line = str(row).strip('[')
  line = line.strip(']')
  return line

classids={}

for row in schoolids4:
    schoolid=row[0].strip()
    classids[schoolid]=0

for row in schoolids5:
    schoolid=row[0].strip()
    if schoolid in classids:
      classids[schoolid]=1
    else:
      fivenot4.write(str(schoolid)+",")
  
for id in classids:
  if classids[id]==0:
    fournot5.write(str(id)+",")
  
