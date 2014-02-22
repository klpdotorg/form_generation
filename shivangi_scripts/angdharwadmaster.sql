select  distinct trim(b2.name) as dist, 
	trim(b1.name) as project, 
	trim(b.name) as circle,
	trim(s.name) as schoolname,
	s.id as schoolid,
        count(stu.id) as stucount
from schools_studentgroup sg,
     schools_student_studentgrouprelation stusg, 
     schools_student stu,
     schools_institution s,
     schools_boundary b,
     schools_boundary b1,
     schools_boundary b2
where 
	s.boundary_id= b.id
	and b.parent_id= b1.id
	and b1.parent_id = b2.id
        and s.id = sg.institution_id 
        and sg.id = stusg.student_group_id 
        and stusg.student_id = stu.id 
        and stu.active = 2 
        and stusg.academic_id = 121 
        and stusg.active=2
        and s.active=2
        and s.id in (select sg.institution_id from schools_answer se,schools_student_studentgrouprelation stusg,schools_studentgroup sg,schools_question q where se.object_id=stusg.student_id and stusg.academic_id=121 and stusg.student_group_id=sg.id and se.question_id=q.id and q.assessment_id=124 and stusg.active=2 and sg.active=2)
        group by b2.name,b1.name,b.name,s.name,s.id
;
 
