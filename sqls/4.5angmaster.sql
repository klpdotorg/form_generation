select distinct
      b2.name as district,
      b1.name as project,
      b.name as circle,
      s.name as preschoolname,
      s.id as preschoolid,
      count(distinct stu.id)
   from schools_studentgroup sg,
     schools_student_studentgrouprelation stusg,
     schools_student stu,
     schools_child c  left outer join schools_relations r on (c.id=r.child_id),
     schools_institution s left outer join schools_staff t on (s.id=t.institution_id and t.staff_type_id=3),
     schools_boundary b,
     schools_boundary b1,
     schools_boundary b2
where
        s.boundary_id= b.id
        and b.parent_id= b1.id
        and b1.parent_id = b2.id
        and b.boundary_type_id=2
        and s.id = sg.institution_id 
        and sg.id = stusg.student_group_id 
        and stusg.student_id = stu.id 
        and stu.active = 2 
        and stusg.academic_id = 122
        and stu.child_id = c.id 
        and stusg.active=2
        and s.active=2
        and (extract(YEAR FROM age(c.dob))*12+extract(month from age(c.dob)))>55
        and b2.id in (8773,9064,9115)
group by b2.name,b1.name,b.name,s.name,s.id
order by b2.name,b1.name,b.name
;

