select distinct
      b2.name as district,
      b1.name as block,
      b.name as ccluster,
      s.name as schoolname,
      s.id as schoolid,
      sg.name as class,
      count(distinct stu.id)
from schools_studentgroup sg,
     schools_student_studentgrouprelation stusg,
     schools_student stu,
     schools_institution s,
     schools_boundary b,
     schools_boundary b1,
     schools_boundary b2
where
        s.boundary_id= b.id and b.parent_id= b1.id and b1.parent_id = b2.id and s.id = sg.institution_id and sg.id = stusg.student_group_id and stusg.student_id = stu.id and stu.active = 2 and stusg.academic_id = 121 and stusg.active=2 and s.active=2 and sg.active=2 
and sg.name in ('1','2','3','4','5')
    and s.id in (36172,36173,36174,36175,36176,36177,36178,36180,36181,36182,36705,35875,35876,35879,35881,35882,35883,35884,36137,36138,36139)
group by b2.name,b1.name,b.name,s.name,s.id,sg.name order by b2.name,b1.name,b.name,s.name,sg.name
;

