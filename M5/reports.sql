/*******************************************
**
** REPORTS
**
*******************************************/

/*******************************************
** 19. deputatkonto
*******************************************/

select 
    res.dozentid
    , res.lastname
    , sum(sumVeranstaltungsSWS+coalesce(sumAufgabenSWS, 0) - kontostandvorsemester) as summe
    , deputat
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
^


/*******************************************
** 20. list all module elements for a degree
*******************************************/
SELECT Teilgebiet, Semester
FROM glkeit00_VERANSTALTUNG
WHERE SPOID = 'SWB' or SPOID = 'IT'
GROUP BY Teilgebiet, Semester
^

/*******************************************
** 21. list external lecturers (SWS+address)
*******************************************/
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
^

/*******************************************
** 22. provided services
*******************************************/
select fak.teilgebiet, tmp.lastname, fak.sws, modul_fak
from ( select distinct teilgebiet
				--, m.spoid
				, fakultaetid as modul_fak
				, sws 
			from glkeit00_modul_spo as m
	join glkeit00_spo as s
	on s.spoid = m.spoid
) as fak
join ( select distinct 
		teilgebiet
		, h.dozentid
		, h.lastname
		, fakultaetid as dozent_fak
	from (select distinct dozentid, lastname, teilgebiet from glkeit00_hat) as h
	join glkeit00_dozent as d
	on h.dozentid = d.dozentid
	and h.lastname = d.lastname
) as tmp
on fak.teilgebiet = tmp.teilgebiet
where fak.modul_fak not like 'IT'
and tmp.dozent_fak = 'IT'

/*******************************************
** 23. used services
*******************************************/
select fak.teilgebiet, tmp.lastname, fak.sws, tmp.dozent_fak
from ( select distinct teilgebiet
				--, m.spoid
				, fakultaetid as modul_fak
				, sws 
			from glkeit00_modul_spo as m
	join glkeit00_spo as s
	on s.spoid = m.spoid
) as fak
join ( select distinct 
		teilgebiet
		, h.dozentid
		, h.lastname
		, fakultaetid as dozent_fak
	from (select distinct dozentid, lastname, teilgebiet from glkeit00_hat) as h
	join glkeit00_dozent as d
	on h.dozentid = d.dozentid
	and h.lastname = d.lastname
) as tmp
on fak.teilgebiet = tmp.teilgebiet
where fak.modul_fak = 'IT'
and tmp.dozent_fak not like 'IT'

