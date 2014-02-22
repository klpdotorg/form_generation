import os
import re
import csv

schoolids= csv.reader(open('/home/shivangi/src/assessments/schools.csv','r'),delimiter=',')

outputfile = open("/home/shivangi/src/assessments/chekfiles.csv",'wb')

def getRow(row):
  line = str(row).strip('[')
  line = line.strip(']')
  return line

for row in schoolids:
    outputfile.write('\n'+getRow(row)+',')
    filename = row[0]+"-*5.pdf"
    outputfile.write(str(filename)+',')
    buffer =os.popen("find . -type f -name %s -exec pdfinfo {} \; | grep Pages" %filename)
    found=0
    for i in buffer:
      found=1
      outputfile.write(i+'\n')
    if found==0:
      outputfile.write("Not found\n")
  
  
