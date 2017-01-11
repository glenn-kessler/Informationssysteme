insert into STUDENT.GLKEIT00_ZEITSEMESTER (ZEITSEMESTERID)
	select distinct 
		akadhj
	from td_stdpl
	^
insert into STUDENT.GLKEIT00_ZEITSEMESTER (ZEITSEMESTERID)
	values
	('SS12'),
	('WS12')
	^
INSERT INTO GLKEIT00_FAKULTAET
	SELECT Fakultaet
	FROM TD_DOZENTEN as td
	WHERE td.Fakultaet is not NULL
	GROUP by td.Fakultaet
	^
INSERT INTO GLKEIT00_DOZENT
	SELECT PRUEFERNUMMER, DOZENT, NULL, Fakultaet
	FROM TD_DOZENTEN as td
	WHERE td.Typ1 is not NULL
	^
INSERT INTO STUDENT.GLKEIT00_PROF
	SELECT PRUEFERNUMMER, DOZENT, TO_DATE(Typ1_Seit, 'DD.MM.YYYY')
	From
	(
		SELECT PRUEFERNUMMER, DOZENT, Typ1, Typ1_Seit
		FROM STUDENT.TD_DOZENTEN as td_doz
		WHERE ((td_doz.Typ1 = 'P' and td_doz.Typ2 is NULL) or (td_doz.Typ1 = 'P' and td_doz.Typ2 = 'LB'))
	)
	^
INSERT INTO STUDENT.GLKEIT00_PROF
	SELECT PRUEFERNUMMER, DOZENT, TO_DATE(Typ2_Seit, 'DD.MM.YYYY')
	From
	(
		SELECT PRUEFERNUMMER, DOZENT, Typ2, Typ2_Seit
		FROM STUDENT.TD_DOZENTEN as td_doz
		WHERE ( td_doz.Typ1 = 'LB' and td_doz.Typ2 = 'P' )
	)
	^
INSERT INTO STUDENT.GLKEIT00_LB
	SELECT PRUEFERNUMMER, 'SS11', DOZENT, TO_DATE(Typ1_Seit, 'DD.MM.YYYY')
	From
	(
		SELECT PRUEFERNUMMER, DOZENT, Typ1, Typ2, Typ1_Seit
		FROM STUDENT.TD_DOZENTEN as td_doz
		WHERE ((td_doz.Typ1 = 'LB' and td_doz.Typ2 is NULL) or (td_doz.Typ1 = 'LB' and td_doz.Typ2 = 'P'))
	)
	^
INSERT INTO STUDENT.GLKEIT00_LB
	SELECT PRUEFERNUMMER, 'SS11', DOZENT, TO_DATE(Typ2_Seit, 'DD.MM.YYYY')
	From
	(
		SELECT PRUEFERNUMMER, DOZENT, Typ2, Typ2_Seit
		FROM STUDENT.TD_DOZENTEN as td_doz
		WHERE ( td_doz.Typ1 = 'P' and td_doz.Typ2 = 'LB' )
	)
	^
INSERT INTO GLKEIT00_PROF_ZEITSEMESTER
	SELECT DEPUTAT_SS11, PRUEFERNUMMER, 'SS11', DOZENT, KONTO_WS10
	FROM
	(
	SELECT PRUEFERNUMMER, DOZENT, DEPUTAT_SS11, DEPUTAT_WS11, KONTO_WS10 
	FROM TD_DOZENTEN as td
	JOIN GLKEIT00_PROF p ON td.PRUEFERNUMMER = p.DOZENTID and td.DOZENT = p.LASTNAME
	WHERE (td.DEPUTAT_SS11 is not NULL)
	)
	^
INSERT INTO GLKEIT00_PROF_ZEITSEMESTER
	SELECT DEPUTAT_WS11, PRUEFERNUMMER, 'WS11', DOZENT, 0
	FROM
	(
	SELECT PRUEFERNUMMER, DOZENT, DEPUTAT_SS11, DEPUTAT_WS11
	FROM TD_DOZENTEN as td
	JOIN GLKEIT00_PROF p ON td.PRUEFERNUMMER = p.DOZENTID and td.DOZENT = p.LASTNAME
	WHERE (td.DEPUTAT_WS11 is not NULL)
	)
	^
INSERT INTO GLKEIT00_SPO
	SELECT Studiengang, 'IT'
	FROM TD_STDPL
	GROUP BY Studiengang
	^
INSERT INTO GLKEIT00_MODUL
	SELECT DISTINCT Studiengang, ModulNr, Teilgebiet, Modulname
	FROM TD_SPO
	^

INSERT INTO GLKEIT00_MODUL
	SELECT
		t1.studiengang,
		nextval FOR GLKEIT00_MODUL_SEQ,
		t1.FACH,
		t1.FACH
	FROM TD_STDPL as t1

	WHERE NOT EXISTS 
	(
		SELECT Teilgebiet

		from GLKEIT00_MODUL as t2
	
		WHERE t1.Fach = t2.Teilgebiet

		AND t1.Studiengang = t2.SPOID
	)
	GROUP BY
		t1.studiengang,
	 	t1.FACH
	^

INSERT INTO GLKEIT00_MODUL_SPO
	SELECT DISTINCT
		ModulNr,
		Teilgebiet,
		Studiengang,
		Semester,
		Credits
	FROM TD_SPO
	^

INSERT INTO GLKEIT00_MODUL_SPO (ModulID, Teilgebiet, SPOID, Semester, SWS)
	select --table with additional teilgebiete from stdpl with sws
		modulid
		, Teilgebiet
		, spoid
		, semester
		, sws
	from (Select distinct --table with counted sws
		modulid,
		Teilgebiet,
		spoid,
		semester,
		count(*)*2 as sws
		from ( select distinct --get modulid where fach and teilgebiet match
			modulid 
			, akadhj 
			, studiengang as spoid
			, semester
			, tag 
			, stunde 
			, fach as Teilgebiet
			from TD_STDPL as p
			JOIN glkeit00_Modul as t1
			ON t1.Teilgebiet = p.fach
			AND t1.spoid = p.studiengang
			where gruppe is NULL  --only resent akadhj and single gruppe
				and ( akadhj = 'WS11' or akadhj = 'SS11' ) --fetch all Modules, independent of winter or summer
		      	or gruppe = 'A'
		)temp
	group BY --count same spoid, semester, teilgebiet for sws
		modulid 
		, akadhj
		, spoid
		, semester
		, Teilgebiet
	)tmp2
	WHERE NOT EXISTS --check if already in modul_spo
	(
		SELECT DISTINCT Studiengang, ModulNr, Teilgebiet, Modulname
		FROM TD_SPO as s
		WHERE s.Teilgebiet = Teilgebiet
		AND s.Studiengang = SPOID
		AND s.ModulNr = Modulid
	)
^

insert into STUDENT.GLKEIT00_Veranstaltung (VERANSTALTUNGSID, ZEITSEMESTERID, MODULID, TEILGEBIET, SPOID, SEMESTER )
select 
	nextval FOR GLKEIT00_VERANSTALTUNG_SEQ as VERANSTALTUNGSID
	, akadhj as zeitsemesterID
	, MODULID
				, fach as teilgebiet
        , studiengang as spoid
        , t1.SEMESTER
from (select distinct
	akadhj
	, fach
	, studiengang
	, semester
	, tag
	, stunde
	, pruefernummer
	, dozent
	from TD_stdpl
	) as p
join glkeit00_Modul_SPO as t1
  ON t1.Teilgebiet = p.fach
  AND t1.spoid = p.studiengang
  AND t1.semester = p.semester

insert into GLKEIT00_HAT (veranstaltungssws, dozentid, veranstaltungsid, lastname)
select 
	'2' as veranstaltungssws --assumption every dozent hat one veranstaltung per week
	, pruefernummer
	, nr
	, dozent
from (	select nr
					, dozent
					, pruefernummer 
				from td_stdpl as stdpl 
				join glkeit00_veranstaltung as v 
				on stdpl.nr = v.veranstaltungsid 
		) as s
join glkeit00_dozent as d
	on s.dozent = d.lastname
	and s.pruefernummer = d.dozentid
where pruefernummer is not null 
and nr is not null
and dozent is not null
^

insert into GLKEIT00_IST_VERANTWORTLICH (SPOID, MODULID, DOZENTID, LASTNAME, TEILGEBIET)
select distinct
	SPOID, MODULID, DOZENTID, LASTNAME, TEILGEBIET
	from (select * 
		from td_stdpl as s 
		join glkeit00_modul_spo as spo 
		on s.fach = spo.teilgebiet 
		and s.studiengang = spo.spoid
	)as temp
	join glkeit00_dozent as d
	on d.dozentid = temp.pruefernummer
	and d.lastname = temp.dozent
^
