--*******************************************
--** 21. list external lecturers (SWS+address)
--******************************************
connect to labor;

select blin2.dozentid, blin2.lastname, blin2.zeitsemesterid, coalesce(blin.summe, 0) as SWS from 

(select 
    res.dozentid
    , res.lastname
    , sum(sumVeranstaltungsSWS+coalesce(sumAufgabenSWS, 0) 
--- kontostandvorsemester
	) as summe
    --, deputat
    , res.zeitsemesterid
from (
  select zsem.dozentid
    , zsem.lastname
    , sumVeranstaltungsSWS
    , deputat
    , kontostandvorsemester
    , zsem.zeitsemesterid 
  from (
    select 
    h.dozentid
    , h.lastname
    , sum(veranstaltungssws) as sumVeranstaltungssws
    , h.zeitsemesterid
    from glkeit00_hat as h
    join glkeit00_veranstaltung as v
    on h.veranstaltungsid = v.veranstaltungsid
    group by dozentid, lastname, h.zeitsemesterid
  )tmp
  join glkeit00_prof_zeitsemester as zsem
  on tmp.zeitsemesterid = zsem.zeitsemesterid
  and tmp.dozentid = zsem.dozentid
  and tmp.lastname = zsem.lastname
)res
full outer join (select 
    dozentid
    , lastname
    , zeitsemesterid
    , sum(aufgabensws) as sumAufgabensws
    from glkeit00_aufgaben 
    group by dozentid
      , lastname
      , zeitsemesterid
    )a
on a.dozentid = res.dozentid
and a.lastname = res.lastname
and a.zeitsemesterid = res.zeitsemesterid
group by 
    res.dozentid
    , res.lastname
    , deputat
    , res.zeitsemesterid
) blin


right outer join (
--Filter für derzeitige LBs
select lb.dozentid, lb.lastname, lb.zeitsemesterid from glkeit00_LB as lb
left outer join glkeit00_prof as p
on lb.dozentid = p.dozentid
where lb.eintrittszeit_lb > p.eintrittszeit_prof 
	OR lb.eintrittszeit_lb is null
) blin2

on 	blin.dozentid = blin2.dozentid	
AND	blin.lastname = blin2.lastname
AND	blin.zeitsemesterid = blin2.zeitsemesterid	
order by blin2.lastname
;
connect reset;