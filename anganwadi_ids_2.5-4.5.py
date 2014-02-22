import os
import web

db=web.database(dbn='postgres',user='klp',pw='never3v3r4g4in',db='klpproduction')

for row in db.query('select distinct inst.id from schools_institution as inst, schools_boundary as dist, schools_boundary as blck, schools_boundary as clst where inst.boundary_id=clst.id and clst.parent_id=blck.id and blck.parent_id= dist.id and dist.id in (8773) and inst.active=2 and inst.id in (select distinct institution_id from schools_studentgroup where id in (select distinct student_group_id from schools_assessment_studentgroup_association where assessment_id in (190,191)))'):
    os.system("perl ang_2.5-4.5.pl -t ang2.5-4.5.tt2 -i "+ str(row.id))

