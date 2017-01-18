--*******************************************
--** 20. list all module elements for a degree
--*******************************************
connect to labor;

SELECT Teilgebiet, Semester
FROM glkeit00_VERANSTALTUNG
WHERE SPOID = 'SWB' or SPOID = 'IT'
GROUP BY Teilgebiet, Semester
order by semester
;

CONNECT RESET;