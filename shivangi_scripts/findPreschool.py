import os
import re
import csv

#data = csv.reader(open('/home/shivangi/src/assessments/preschools1.csv','r'),delimiter='|')
data = csv.reader(open('/home/shivangi/src/assessments/koppal_preschools.csv','r'),delimiter=',')

outputfile = open("/home/shivangi/src/assessments/preschool_master.csv",'wb')

schools={}

def getRow(row):
  line = str(row).strip('[')
  line = line.strip(']')
  return line

firstRow=1
for row in data:
    schoolid=row[0].strip()
    if schoolid in schools:
      print "Duplicate "+schoolid
      continue
    else:
       schools[schoolid]=1
    filename = schoolid+"-*reordered.pdf"
    buffer =os.popen("find . -type f -name %s -exec pdfinfo {} \; | grep Pages" %filename)
    found=0
    for i in buffer:
      found=1
      outputfile.write(filename+','+schoolid+','+i)
    if found==0:
      print "File not found :"+str(schoolid)
      outputfile.write("\n")
  
  
