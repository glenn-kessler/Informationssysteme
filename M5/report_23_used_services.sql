--*******************************************
--** 23. used services
--*******************************************/
connect to labor;

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
order by tmp.lastname
;

connect reset;