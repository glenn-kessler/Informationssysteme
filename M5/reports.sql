/*******************************************
**
** REPORTS
**
*******************************************/

/*******************************************
** 19. deputatkonto
*******************************************/
select 
  dozentid
  , lastname
  , sum(bilanz) as bilanz
from (
  select zsem.dozentid
    , zsem.lastname
    , (sum - deputat) as bilanz
    , zsem.zeitsemesterid 
  from (
    select 
    dozentid
    , lastname
    , sum(veranstaltungssws) as sum
    , zeitsemesterid
    from glkeit00_hat as h
    join glkeit00_veranstaltung as v
    on h.veranstaltungsid = v.veranstaltungsid
    group by dozentid, lastname, zeitsemesterid
  )tmp
  join glkeit00_prof_zeitsemester as zsem
  on tmp.zeitsemesterid = zsem.zeitsemesterid
  and tmp.dozentid = zsem.dozentid
  and tmp.lastname = zsem.lastname
)res
group by dozentid
  , lastname
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
--TODO!!!
SELECT *
FROM glkeit00_LB as LB
LEFT OUTER JOIN glkeit00_PROF as PROF
ON LB.DozentID = PROF.DozentID
^

/*******************************************
** 22. provided services
*******************************************/


/*******************************************
** 23. used services
*******************************************/


/*******************************************
** 24. 
*******************************************/
