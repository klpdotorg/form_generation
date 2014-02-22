import os
import re
import csv

#data = csv.reader(open('/home/shivangi/src/assessments/preschools1.csv','r'),delimiter='|')
data = csv.reader(open('/home/shivangi/src/assessments/oneoff_preschools.csv','r'),delimiter=',')

outputfile = open("/home/shivangi/src/assessments/preschool_master.csv",'wb')

def getRow(row):
  line = str(row).strip('[')
  line = line.strip(']')
  return line

firstRow=1
for row in data:
  if firstRow:
      outputfile.write(getRow(row)+',Number of students,Pages\n')
      firstRow=0
  else:
    schoolid=row[0].strip()
    numstudents=row[1].strip()
    outputfile.write(getRow(row)+',')
    buffer = os.popen("grep %s output.txt" %schoolid)
    for i in buffer:
      matchstr = "^"+schoolid+"-.*students:-"+numstudents
      match = re.match(matchstr,i)
      if match == None:
        print "ERROR:- "+str(row)+" "+i
    filename = schoolid+"-*reordered.pdf"
    buffer =os.popen("find . -type f -name %s -exec pdfinfo {} \; | grep Pages" %filename)
    found=0
    for i in buffer:
      found=1
      outputfile.write(i)
    if found==0:
      print "File not found :"+str(schoolid)+","+str(numstudents)
      outputfile.write("\n")
  
  
