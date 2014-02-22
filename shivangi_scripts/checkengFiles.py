import os
import re
import csv

schoolids= csv.reader(open('/home/shivangi/src/reports/eng4schoolcount.csv','r'),delimiter='|')

outputfile = open("/home/shivangi/src/assessments/checkengfiles4.csv",'wb')

def getRow(row):
  line = str(row).strip('[')
  line = line.strip(']')
  return line

for row in schoolids:
    schoolid=row[3].strip()
    filename = str(schoolid)+"-*4.pdf"
    buffer =os.popen("find english -type f -name %s -exec pdfinfo {} \; | grep Pages" %filename)
    found=0
    for i in buffer:
      found=1
    if found==0:
      outputfile.write('\n'+getRow(row)+',')
      outputfile.write("Not found\n")
  
  
