--------------------------------------------
-- deputatkonto
--------------------------------------------
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
