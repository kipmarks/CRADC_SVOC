/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 112_excl_first_arrangements.sas

Overview:     STUB ONLY - COMPLEX PASS-THROUGH SQL NEEDS REWRITE.
              
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
2015-2019  	Original EXCL development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/
%put INFO-112_excl_first_arrangements.sas: STUB ONLY;

%GetStarted;
/*********************************************************************************************************************************/
/*  FIRST Arrangements code
/*  Apr 2019 CG - No changes required as process already built for co-existence
/*  Separate code for FIRST and START assesses compliance separately in each system
/*  The results from the separate code are combined in Step 4 Campaign Process
/*  To work out overall compliance picture
/*********************************************************************************************************************************/
%drop_edw(arrangements_exclusions);
%drop_edw(arrangements_exclusions_1);
%drop_edw(arrangements_exclusions_1a);
%drop_edw(arrangements_exclusions_1aa);
%drop_edw(arrangements_exclusions_1aaa);
%drop_edw(arrangements_exclusions_1b);
%drop_edw(arrangements_exclusions_1c);
%drop_edw(arrangements_exclusions_1cc);
%drop_edw(arrangements_exclusions_1d);
%drop_edw(arrangements_exclusions_1dd);
%drop_edw(arrangements_exclusions_1e);
%drop_edw(aa_arrangements);
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
EXECUTE(
CREATE TABLE ARRANGEMENTS_EXCLUSIONS AS
WITH A1 AS (SELECT 
          DISTINCT A.IRD_NUMBER,
                   A.LOCATION_NUMBER,
                   A.CASE_NUMBER,
                   A.CASE_TYPE_CODE,
                   A.ARRANGEMENT_NUMBER,
                   LAST_VALUE(A.DATE_APPLIED) OVER(PARTITION BY A.IRD_NUMBER, 
                                                                A.LOCATION_NUMBER, 
                                                                A.CASE_NUMBER, 
                                                                A.CASE_TYPE_CODE, 
                                                                A.ARRANGEMENT_NUMBER 
                                                       ORDER BY A.ARRANGEMENT_NUMBER, 
                                                                A.DATE_APPLIED ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS DATE_APPLIED

              FROM DSS.INSTALMENT_AGMT_ELEMENTS_VALL A
             WHERE A.DATE_CEASED IS NULL AND
                   A.CASE_TYPE_CODE = 'CN' AND
                   A.ARRANGEMENT_ELEMENT_STATUS IN('A','S')
                   /*        AND   A.DATE_END IS NULL /*CAN'T HAVE THIS LIMIT BECAUSE SOME ACTIVE CASES (FOR SOME REASON) HAVE A DATE CEASED AS NULL BUT HAVE A DATE_END DATE*/
                   /*              AND THEY DON'T HAVE ANY DATE_END IS NULL AND DATE_CEASED IS NULL          */
                   /*        AND   A.IRD_NUMBER IN (19571327,25346211,61561390,88897579,109019860,63826227,81618917)*/
          GROUP BY A.IRD_NUMBER,
                   A.LOCATION_NUMBER,
                   A.CASE_NUMBER,
                   A.ARRANGEMENT_NUMBER,
                   A.CASE_TYPE_CODE,
                   A.DATE_APPLIED),
     A2 AS (SELECT 
          DISTINCT POP.IRD_NUMBER,
                   POP.LOCATION_NUMBER,
                   POP.CASE_NUMBER,
                   POP.ARRANGEMENT_NUMBER,
                   POP.CASE_TYPE_CODE,
                   POP.DATE_CEASED,
                   POP.DATE_APPLIED,
                   A.DATE_CREATED,
                   A.DATE_START,
                   A.TOTAL_AMOUNT                   AS TOTAL_AGMT_AMOUNT,
                   A.ACTUAL_ARRANGEMENT_PAYMENT_AMT AS TOTAL_ARRANGEMENT_PAYMENT,
                   A.EXPECTED_PAYMENT_AMOUNT        AS TOTAL_EXPECTED_PAYMENT,
                   A.DATE_EXPECTED_PAYMENT_DUE
              FROM DSS.INSTALMENT_SRC_PLANS_SUM_VALL A
              JOIN (SELECT DISTINCT A.IRD_NUMBER,
                                    A.LOCATION_NUMBER,
                                    A.CASE_NUMBER,
                                    A.ARRANGEMENT_NUMBER,
                                    A.CASE_TYPE_CODE,
                                    LAST_VALUE(A.DATE_CEASED)  OVER(PARTITION BY A.IRD_NUMBER, 
                                                                                 A.LOCATION_NUMBER, 
                                                                                 A.CASE_NUMBER, 
                                                                                 A.ARRANGEMENT_NUMBER 
                                                                        ORDER BY A.ARRANGEMENT_NUMBER, 
                                                                                 A.DATE_CEASED ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS DATE_CEASED,
                  
                                    LAST_VALUE(A.DATE_APPLIED) OVER(PARTITION BY A.IRD_NUMBER, 
                                                                                 A.LOCATION_NUMBER, 
                                                                                 A.CASE_NUMBER, 
                                                                                 A.ARRANGEMENT_NUMBER 
                                                                        ORDER BY A.ARRANGEMENT_NUMBER, 
                                                                                 A.DATE_APPLIED ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS DATE_APPLIED
                           FROM DSS.INSTALMENT_SRC_PLANS_SUM_VALL A
                           JOIN DSS.RADC_SVOC_VALL                B ON A.IRD_NUMBER = B.IRD_NUMBER AND
                                                                       A.LOCATION_NUMBER = B.LOCATION_NUMBER AND
                                                                       A.CASE_NUMBER = B.CASE_NUMBER AND
                                                                       A.CASE_TYPE_CODE = 'CN' AND
                                                                       /*AND A.IRD_NUMBER IN (19571327,25346211,61561390,88897579,109019860,63826227,81618917)*/
                                                                       A.DATE_CEASED IS NULL) POP ON A.IRD_NUMBER = POP.IRD_NUMBER AND
                                                                                                     A.LOCATION_NUMBER = POP.LOCATION_NUMBER AND
                                                                                                     A.CASE_NUMBER = POP.CASE_NUMBER AND
                                                                                                     A.ARRANGEMENT_NUMBER = POP.ARRANGEMENT_NUMBER AND
                                                                                                     A.DATE_APPLIED = POP.DATE_APPLIED AND
                                                                                                     A.CASE_TYPE_CODE = 'CN' AND
                                                                                                     A.TOTAL_AMOUNT > 1 /*JUST TO MAKE SURE WE ARE PICKING UP ACTUAL ARRANGEMENTS*/ AND
                                                                                                     A.DATE_CEASED IS NULL),

/*CAN USE MORE THAN ONE MAX STATEMENT AS THE DATE_START IS IN THE GROUP BY*/
     A3 AS (SELECT C.IRD_NUMBER,
                   C.LOCATION_NUMBER,
                   C.CASE_NUMBER,
                   C.CASE_TYPE_CODE,
                   C.ARRANGEMENT_NUMBER,
                   MAX(C.DATE_START) AS DATE_START,
                   MAX(C.DATE_END) AS DATE_END,
                   TO_CHAR(C.DATE_START,'MON YYYY') AS MONTH
              FROM DSS.INSTALMENT_SRC_PLANS_VALL C
             WHERE C.DATE_CEASED IS NULL AND
                   C.CASE_TYPE_CODE = 'CN' AND
                   C.DATE_END IS NOT NULL AND
                   /*     AND   C.IRD_NUMBER IN (19571327,25346211,61561390,88897579,109019860,63826227,81618917)*/
                   C.ARRANGEMENT_NUMBER IS NOT NULL
          GROUP BY C.IRD_NUMBER,
                   C.LOCATION_NUMBER,
                   C.CASE_NUMBER,
                   C.CASE_TYPE_CODE,
                   C.DATE_START,
                   C.ARRANGEMENT_NUMBER),
          
     A4 AS  (SELECT D.IRD_NUMBER,
                    D.LOCATION_NUMBER,
                    D.CASE_NUMBER,
                    D.CASE_TYPE_CODE,
                    D.ARRANGEMENT_NUMBER,
                    D.INST_SRC_PLAN_TYPE_CODE,
                    D.DATE_START,
                    D.DATE_END
               FROM DSS.INSTALMENT_SRC_PLANS_VALL D
            /*WHERE D.IRD_NUMBER IN (19571327,25346211,61561390,88897579,109019860,63826227,81618917)*/)

        SELECT 
      DISTINCT A1.IRD_NUMBER,
               A1.LOCATION_NUMBER,
               A1.CASE_NUMBER,
               A3.ARRANGEMENT_NUMBER,
               /*A1.TAX_TYPE_COUNT,*/
               A2.TOTAL_AGMT_AMOUNT,
               A2.TOTAL_ARRANGEMENT_PAYMENT,
               A2.TOTAL_EXPECTED_PAYMENT,
               A2.DATE_APPLIED,
               A2.DATE_CEASED,
               A3.MONTH,
               A3.DATE_START,
               A3.DATE_END,
               A2.DATE_EXPECTED_PAYMENT_DUE,
               A4.INST_SRC_PLAN_TYPE_CODE
          FROM A1
          JOIN A2 ON A1.IRD_NUMBER = A2.IRD_NUMBER AND
                     A1.LOCATION_NUMBER = A2.LOCATION_NUMBER AND
                     A1.CASE_NUMBER = A2.CASE_NUMBER AND
                     A1.CASE_TYPE_CODE = A2.CASE_TYPE_CODE AND
                     A1.ARRANGEMENT_NUMBER = A2.ARRANGEMENT_NUMBER
          JOIN A3 ON A1.IRD_NUMBER = A3.IRD_NUMBER AND
                     A1.LOCATION_NUMBER = A3.LOCATION_NUMBER AND
                     A1.CASE_NUMBER = A3.CASE_NUMBER AND
                     A1.CASE_TYPE_CODE = A3.CASE_TYPE_CODE AND
                     A1.ARRANGEMENT_NUMBER = A3.ARRANGEMENT_NUMBER
          JOIN A4 ON A1.IRD_NUMBER = A4.IRD_NUMBER AND
                     A1.LOCATION_NUMBER = A4.LOCATION_NUMBER AND
                     A1.CASE_NUMBER = A4.CASE_NUMBER AND
                     A1.CASE_TYPE_CODE = A4.CASE_TYPE_CODE AND
                     A3.ARRANGEMENT_NUMBER = A4.ARRANGEMENT_NUMBER AND
                     A3.DATE_START = A4.DATE_START AND
                     A3.DATE_END = A4.DATE_END
         WHERE A3.DATE_END > SYSDATE AND
               A3.DATE_START <= A3.DATE_END)BY MYORACON;
   disconnect from myoracon;
   quit;
/*********************************************************************************************************************************/
/*   Create oracle index to speed up join to DSS
/*********************************************************************************************************************************/
PROC SQL;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
execute (CREATE INDEX arrangements_exclusions_IX ON arrangements_exclusions (IRD_number, location_number, case_number)) by myoracon;
disconnect from myoracon;
quit;
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
create table DW.arrangements_exclusions_1 as
select * from connection to myoracon
(
SELECT  a.ird_number                              ,
        a.location_number                         ,
        a.case_number                             ,
        a.ARRANGEMENT_NUMBER                      ,
        a.total_agmt_amount                       ,
        a.total_arrangement_payment               ,
        a.total_expected_payment                  ,
        a.date_applied                            ,
        a.date_end                                ,
        a.date_start                              ,
        a.date_expected_payment_due               ,
      a.inst_src_plan_type_code              ,
        b.source_plan_number
        

FROM arrangements_exclusions a LEFT JOIN 

(SELECT b.ird_number                              ,
        b.location_number                         ,
        b.case_number                             ,
        MAX (a.source_plan_number) as source_plan_number
FROM DSS.instalment_phases_VALL a INNER JOIN arrangements_exclusions b

ON a.ird_number = b.ird_number
and a.location_number = b.location_number
AND a.case_number = b.case_number
AND a.case_type_code = 'CN'
AND b.date_end > sysdate
/*AND a.ird_number IN (19571327,25346211,61561390,88897579,109019860,63826227,81618917) */
GROUP BY b.ird_number                             ,
        b.location_number                         ,
        b.case_number                               ) b

ON a.ird_number       = b.ird_number
AND a.location_number = b.location_number
AND a.case_number     = b.case_number
/*AND a.ird_number IN (19571327,25346211,61561390,88897579,109019860,63826227,81618917) */
   );
   disconnect from myoracon;
   quit;
/*********************************************************************************************************************************/
PROC SQL;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
execute (CREATE INDEX arrangements_exclusions_1_IX ON arrangements_exclusions_1 (IRD_number, location_number, case_number)) by myoracon;
;
disconnect from myoracon;
quit;
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
create table DW.arrangements_exclusions_1a as
select * from connection to myoracon
(   SELECT   DISTINCT
           a.*,
           b.frequency_code,
           b.date_start AS PHASE_DATE_START,
           b.date_end AS PHASE_DATE_END,
           b.phase_amount,
           b.payment_quantity,
           CASE WHEN b.date_start < sysdate AND b.date_end > sysdate THEN 'Y' ELSE 'N' END AS CURRENT_PHASE
   FROM    arrangements_exclusions_1 a
   LEFT JOIN 
           dss.instalment_phases_VALL b 
           ON a.ird_number = b.ird_number and a.location_number = b.location_number AND a.case_number = b.case_number
         AND b.case_type_code = 'CN'
         AND a.source_plan_number = b.source_plan_number

   ORDER BY 1
);
   disconnect from myoracon;
   quit;
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
create table DW.arrangements_exclusions_1aa as
select * from connection to myoracon
(   SELECT   DISTINCT
          a.*
           ,LAST_VALUE(a.CURRENT_PHASE)   OVER (PARTITION BY a.ird_number, a.location_number, a.case_number, a.arrangement_number 
                                 ORDER BY a.arrangement_number, a.CURRENT_PHASE ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
                                             ) AS CURRENT_PHASE_IRD_NU
         ,CASE   WHEN overlap.ird_number > 1 THEN 'O'
               WHEN amountsum.ird_number > 1 THEN 'A'
               END AS integrity_issue_code
   FROM    arrangements_exclusions_1a a
     LEFT JOIN
           (
         /* detect phase overlapping      */
         /* tag at level of ird/loc/case */
           SELECT   DISTINCT
                   ird_number, location_number, case_number
           FROM
                   (   SELECT   a.ird_number, a.location_number, a.case_number,
                        case   when lead(phase_date_start) over (partition by a.ird_number,a.location_number,a.case_number order by a.phase_date_start)<=phase_date_end then 'OVERLAP' 
                                       end as issue                         
                      FROM    arrangements_exclusions_1a a
                   ) 
           WHERE issue='OVERLAP'
           ) overlap
           ON a.ird_number = overlap.ird_number and a.location_number = overlap.location_number AND a.case_number = overlap.case_number
   LEFT JOIN
           (
         /* detect phase overlapping      */
         /* tag at level of ird/loc/case */
           SELECT   DISTINCT
                   ird_number, location_number, case_number
           FROM
                   (   SELECT   a.ird_number, a.location_number, a.case_number,
                        sum(phase_amount) over (partition by a.ird_number, a.location_number, a.case_number) as phase_sum_amount,
                        sum(phase_amount) over (partition by a.ird_number, a.location_number, a.case_number) - total_agmt_amount as phase_sum_diff_amount
                      FROM    arrangements_exclusions_1a a
                   ) 
           WHERE phase_sum_diff_amount>=0.01
           ) amountsum
           ON a.ird_number = amountsum.ird_number and a.location_number = amountsum.location_number AND a.case_number = amountsum.case_number
   );
   disconnect from myoracon;
   quit; 
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
create table DW.arrangements_exclusions_1aaa as
select * from connection to myoracon
(SELECT DISTINCT
a.*,
        CASE  WHEN b.ird_number > 1 THEN 'Y' 
              WHEN CURRENT_PHASE_IRD_NU = 'N' THEN 'N'
        END AS OTH_PHASE_NO_CURRENT,
        CASE WHEN a.phase_date_start < sysdate-1 AND a.phase_date_end < sysdate-1 THEN 'Y' ELSE 'N' END AS PREVIOUS_PHASE
  
  FROM arrangements_exclusions_1aa a 

LEFT JOIN

(SELECT ird_number,
location_number,
case_number,
arrangement_number,
MIN(phase_date_start) as phase_date_start
FROM arrangements_exclusions_1aa
WHERE CURRENT_PHASE_IRD_NU = 'N'
GROUP BY 
ird_number,
location_number,
case_number,
arrangement_number) b

ON a.ird_number = b.ird_number
AND a.location_number = b.location_number
AND a.case_number = b.case_number
AND a.phase_date_start = b.phase_date_start
   );
   disconnect from myoracon;
   quit; 
/*********************************************************************************************************************************/
/*create SAS date as can't use ADD_MONTHS function in passthrough
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE arrangements_exclusions_date AS
SELECT 
*,
datepart(PHASE_DATE_START) format ddmmyy10. as PHASE_DATE_START_2
FROM DW.arrangements_exclusions_1aaa;
QUIT;
/*********************************************************************************************************************************/
proc sql;
CREATE TABLE DW.arrangements_exclusions_1b AS
SELECT
a.*,
   CASE WHEN a.CURRENT_PHASE = 'Y' AND a.frequency_code = 'WK' THEN intnx('week',a.PHASE_DATE_START_2,3,'same') ELSE
        CASE WHEN a.CURRENT_PHASE = 'Y' AND a.frequency_code = 'FN' THEN intnx('week',a.PHASE_DATE_START_2,6,'same') ELSE
        CASE WHEN a.CURRENT_PHASE = 'Y' AND a.frequency_code = '4W' THEN intnx('week',a.PHASE_DATE_START_2,12,'same') ELSE
      CASE WHEN a.CURRENT_PHASE = 'Y' AND a.frequency_code = 'MO' THEN intnx('month',a.PHASE_DATE_START_2,3,'same')  
      END 
END END END AS THREE_MISSED_PAY_DATE format ddmmyy10.
FROM arrangements_exclusions_date a;
QUIT;
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
create table DW.arrangements_exclusions_1c as
select * from connection to myoracon
(

WITH

a1 AS

 ( SELECT DISTINCT
        a.* 
    FROM arrangements_exclusions_1b a
 ),
        
a2 AS        
        
(   SELECT a.*,
         sum(a.PHASE_AMOUNT) OVER (PARTITION BY ird_number, location_number, case_number, arrangement_number) as TOTAL_EXPECTED_PRE_PHASES
    FROM arrangements_exclusions_1b a
    WHERE PREVIOUS_PHASE = 'Y'
)

SELECT DISTINCT A1.IRD_NUMBER,
            A1.LOCATION_NUMBER,
            A1.CASE_NUMBER,
            A1.ARRANGEMENT_NUMBER,
            A1.TOTAL_AGMT_AMOUNT,
            A1.TOTAL_ARRANGEMENT_PAYMENT,
            A1.TOTAL_EXPECTED_PAYMENT,
            A1.DATE_APPLIED,
            A1.DATE_END,
            A1.DATE_START,
            A1.DATE_EXPECTED_PAYMENT_DUE,
            A1.INST_SRC_PLAN_TYPE_CODE,
            A1.SOURCE_PLAN_NUMBER,
            A1.FREQUENCY_CODE,
            A1.PHASE_DATE_START,
            A1.PHASE_DATE_END,
            A1.PHASE_AMOUNT,
            A1.PAYMENT_QUANTITY,
            A1.CURRENT_PHASE,
            A1.CURRENT_PHASE_IRD_NU,
            A1.INTEGRITY_ISSUE_CODE,
            A1.OTH_PHASE_NO_CURRENT,
            A1.PREVIOUS_PHASE,
            A1.THREE_MISSED_PAY_DATE,
                A2.TOTAL_EXPECTED_PRE_PHASES

     FROM A1
      LEFT JOIN A2
      ON A1.ird_number = A2.ird_number
      AND A1.location_number = A2.location_number
      AND A1.case_number = A2.case_number
      AND A1.arrangement_number = A2.arrangement_number

   );
   disconnect from myoracon;
   quit; 
/*********************************************************************************************************************************/
/*get one line of data for arrangements.
/*arrangement that are currently active get their current phase. Arrangement that
/*are due to start get their next phase
/*********************************************************************************************************************************/
proc sql;
CREATE TABLE DW.arrangements_exclusions_1cc AS
SELECT *
FROM DW.arrangements_exclusions_1c
WHERE CURRENT_PHASE = 'Y'
OR OTH_PHASE_NO_CURRENT = 'Y'
;
QUIT;

/*********************************************************************************************************************************/
/*  Create table to work out the estimated payments for an arrangment. Because the  arrangement always starts on the first day we 
/*  have to add +1 to our calculation to work out the actual number of payments required. We also need to add on amounts that have
/*  already been expected from previous phases that have already past
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
create table DW.arrangements_exclusions_1d as
select * from connection to myoracon
(SELECT  DISTINCT a.*,
      to_number(
        CASE WHEN CURRENT_PHASE = 'Y' AND a.frequency_code = 'WK' THEN TRUNC((sysdate-a.phase_date_start)/7,0)+1 ELSE   
        CASE WHEN CURRENT_PHASE = 'Y' AND a.frequency_code = '4W' THEN TRUNC((sysdate-a.phase_date_start)/28,0)+1 ELSE
        CASE WHEN CURRENT_PHASE = 'Y' AND a.frequency_code = 'MO' THEN TRUNC(months_between(sysdate, a.phase_date_start),0)+1 ELSE
        CASE WHEN CURRENT_PHASE = 'Y' AND a.frequency_code = 'FN' THEN TRUNC((sysdate-a.phase_date_start)/14,0)+1 ELSE
        0     
        END END END END) as number_of_expected_payments,
        
      to_number(
        CASE WHEN CURRENT_PHASE = 'Y' AND a.frequency_code = 'WK' THEN NVL(a.phase_amount/a.payment_quantity,0)* (TRUNC((sysdate-a.phase_date_start)/7,0)+1) + NVL(TOTAL_EXPECTED_PRE_PHASES,0) ELSE
        CASE WHEN CURRENT_PHASE = 'Y' AND a.frequency_code = '4W' THEN NVL(a.phase_amount/a.payment_quantity,0)* (TRUNC((sysdate-a.phase_date_start)/28,0)+1) + NVL(TOTAL_EXPECTED_PRE_PHASES,0) ELSE
        CASE WHEN CURRENT_PHASE = 'Y' AND a.frequency_code = 'MO' THEN NVL(a.phase_amount/a.payment_quantity,0)* (TRUNC(months_between(sysdate, a.phase_date_start),0)+1)+ NVL(TOTAL_EXPECTED_PRE_PHASES,0) ELSE
        CASE WHEN CURRENT_PHASE = 'Y' AND a.frequency_code = 'FN' THEN NVL(a.phase_amount/a.payment_quantity,0)* (TRUNC((sysdate-a.phase_date_start)/14,0)+1) + NVL(TOTAL_EXPECTED_PRE_PHASES,0) ELSE
        CASE WHEN CURRENT_PHASE = 'N' THEN NVL(TOTAL_EXPECTED_PRE_PHASES,0) 
      ELSE   a.total_expected_payment 
        END END END END END) as total_expected_payment_cal

FROM arrangements_exclusions_1cc a  
   );
   disconnect from myoracon;
   quit;
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE differences AS
SELECT
POP.*
,
CASE WHEN a.counting <> b.counting then 'DOUBLE' ELSE 'FINE' END AS TEST
FROM
DW.arrangements_exclusions_1d pop

JOIN

(
SELECT
COUNT(a.ird_number) as counting,
a.ird_number,
a.location_number,
a.case_number
FROM DW.arrangements_exclusions a
GROUP BY 
a.ird_number,
a.location_number,
a.case_number
) a
ON pop.ird_number = a.ird_number
AND pop.location_number = a.location_number
AND pop.case_number = a.case_number

JOIN
(SELECT
COUNT(ird_number) as counting,
ird_number,
location_number,
case_number
FROM DW.arrangements_exclusions_1d
GROUP BY 
ird_number,
location_number,
case_number

) b
ON POP.ird_number = b.ird_number
AND POP.location_number = b.location_number
AND POP.case_number = b.case_number



;
/*********************************************************************************************************************************/
PROC SORT data=differences;
BY IRD_NUMBER LOCATION_NUMBER CASE_NUMBER;
RUN;
/*********************************************************************************************************************************/
Data differences_2;
SET differences;
BY IRD_NUMBER LOCATION_NUMBER CASE_NUMBER ;
IF FIRST.IRD_NUMBER 
AND TEST = 'DOUBLE' 
THEN output;
RUN;
/*********************************************************************************************************************************/
PROC SQL;
CREATE TABLE DW.arrangements_exclusions_1dd AS
SELECT a.*
FROM differences a
WHERE TEST = 'FINE'

UNION
SELECT b.*
FROM differences_2 b
;
QUIT;
/*********************************************************************************************************************************/
proc sql;
CREATE   TABLE DW.arrangements_exclusions_1e AS
SELECT   DISTINCT a.*,
      CASE    WHEN INTEGRITY_ISSUE_CODE is not null then INTEGRITY_ISSUE_CODE
            WHEN multi.ird_number > 1 THEN 'M'
            END AS INTEGRITY_ISSUE
FROM    DW.arrangements_exclusions_1dd a
LEFT JOIN
      (SELECT b.ird_number,
            b.location_number,
            b.case_number
      FROM DW.arrangements_exclusions_1dd b   
      GROUP BY b.ird_number,
            b.location_number,
            b.case_number
      HAVING COUNT(ird_number) > 1
      ) multi
      ON a.ird_number = multi.ird_number AND a.location_number = multi.location_number AND a.case_number = multi.case_number
ORDER    BY a.ird_number, a.location_number, a.case_number;
QUIT;
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1" path=dwp);
create table CMP_ARRANGEMENTS_EXCLUSIONS_2 as
select * from connection to myoracon
(SELECT  DISTINCT
        a.ird_number,
          a.location_number,
        a.case_number,
          a.arrangement_number,
          a.total_agmt_amount,
        a.INST_SRC_PLAN_TYPE_CODE,
        a.total_arrangement_payment,
          a.total_expected_payment, /*from summary table*/
          a.total_expected_payment_cal, /*calculated above from phases view this is the figure we are interest in*/
          a.date_start,
          a.date_end,
        a.current_phase,
        CASE WHEN OTH_PHASE_NO_CURRENT = 'Y' AND PREVIOUS_PHASE = 'Y' THEN '' ELSE a.frequency_code END AS frequency_code,
        a.current_phase_ird_nu,
        CASE WHEN a.phase_date_start < (to_date(sysdate,'YYYY.MM.DD HH24:MI:SS')) and a.phase_date_end < (to_date(sysdate,'YYYY.MM.DD HH24:MI:SS'))
        THEN to_date('99/01/01','YYYY.MM.DD HH24:MI:SS') ELSE a.phase_date_start END AS phase_date_start,
        CASE WHEN a.phase_date_start < (to_date(sysdate,'YYYY.MM.DD HH24:MI:SS')) and a.phase_date_end < (to_date(sysdate,'YYYY.MM.DD HH24:MI:SS'))
        THEN to_date('99/01/01','YYYY.MM.DD HH24:MI:SS') ELSE a.phase_date_end END AS phase_date_end,
        a.previous_phase,
        a.three_missed_pay_date,
        a.number_of_expected_payments,
        a.total_expected_pre_phases,
        a.INTEGRITY_ISSUE,
        CASE  WHEN total_agmt_amount > 0
              THEN ROUND((ABS(ABS(NVL(total_arrangement_payment,0))-ABS(NVL(total_expected_payment_cal,0)))/ABS(NVL(total_agmt_amount,0)))*100,2) ELSE 0
              END AS percent_diff,
   
        CASE   WHEN             /*Y= (payment>expected) or (start_date later than 5 days ago)*/
                           total_arrangement_payment > total_expected_payment_cal OR date_start > ((to_date(sysdate,'YYYY.MM.DD HH24:MI:SS'))-5) THEN 'Y' 
            ELSE CASE   WHEN    /*Y= doubled up*/
                           a.INTEGRITY_ISSUE is not null THEN 'Y' 
            ELSE CASE    WHEN    /*Y= expected > agm_amount */
                           a.TOTAL_EXPECTED_PAYMENT_CAL > a.TOTAL_AGMT_AMOUNT THEN 'Y' 
            ELSE CASE    WHEN    /*N= agm_date_end  < now */
                           total_agmt_amount > 0 AND date_end < (to_date(sysdate,'YYYY.MM.DD HH24:MI:SS')) THEN 'N' 
            ELSE CASE   WHEN    /*N= agm_amount >10k and pct_diff>5% and (three_missed has passed or has no_current_phase*/
                           total_agmt_amount > 10000.01 AND ROUND((ABS(ABS(NVL(total_arrangement_payment,0))-ABS(NVL(total_expected_payment_cal,0)))/ABS(NVL(total_agmt_amount,0)))*100,2)>5 AND (to_date(three_missed_pay_date,'YYYY.MM.DD HH24:MI:SS') < sysdate OR three_missed_pay_date IS NULL) THEN 'N' 
            ELSE CASE     WHEN    /*N= agm_amount 1k-10k and pct_diff>10% and (three_missed has passed or has no_current_phase*/
                           total_agmt_amount BETWEEN 1001.01 AND 10000.01 AND ROUND((ABS(ABS(NVL(total_arrangement_payment,0))-ABS(NVL(total_expected_payment_cal,0)))/ABS(NVL(total_agmt_amount,0)))*100,2)>10 AND (to_date(three_missed_pay_date,'YYYY.MM.DD HH24:MI:SS') < sysdate OR three_missed_pay_date IS NULL)        THEN 'N' 
            ELSE CASE     WHEN    /*N= agm_amount <1k and pct_diff>30% and (three_missed has passed or has no_current_phase*/   
                           total_agmt_amount BETWEEN 0.01 AND 1000   AND ROUND((ABS(ABS(NVL(total_arrangement_payment,0))-ABS(NVL(total_expected_payment_cal,0)))/ABS(NVL(total_agmt_amount,0)))*100,2)>30         AND (to_date(three_missed_pay_date,'YYYY.MM.DD HH24:MI:SS') < sysdate      OR three_missed_pay_date IS NULL)        THEN 'N' 
            ELSE 'Y'
            END 
            END
            END
            END
            END
            END
            END AS active_arrangement  

  
  FROM arrangements_exclusions_1e a

   );
   disconnect from myoracon;
   quit;
/*********************************************************************************************************************************/
proc sql;
CREATE TABLE CMP_ARRANGEMENTS_EXCLUSIONS AS  
SELECT today() format date9. as EXTRACTED_DATE, a.*
FROM cmp_arrangements_exclusions_2 a
WHERE active_arrangement = 'Y';
QUIT;
/*********************************************************************************************************************************/
DATA DW.aa_arrangements;
SET DW.arrangements_exclusions;
RUN;
PROC SQL;
CONNECT TO ORACLE(USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP);
EXECUTE(DELETE FROM AA_ARRANGEMENTS T WHERE T.IRD_NUMBER IN (SELECT IRD_NUMBER FROM SPECIAL_CLIENTS))BY ORACLE;
EXECUTE(COMMIT)BY ORACLE;
EXECUTE(GRANT SELECT ON AA_ARRANGEMENTS TO USER_CAMPAIGNS) BY ORACLE;
DISCONNECT FROM ORACLE;
QUIT;
/*********************************************************************************************************************************/
PROC SORT DATA=CMP_ARRANGEMENTS_EXCLUSIONS  
  OUT=EXCLTEMP.CMP_ARRANGEMENTS_EXCLUSIONS 
        DUPOUT=CMP_ARRANGEMENTS_EXCLUSIONS_D NODUPKEY;
BY IRD_NUMBER;
RUN;

PROC SORT DATA=CMP_ARRANGEMENTS_EXCLUSIONS_2  
  OUT=EXCLTEMP.CMP_ARRANGEMENTS_EXCLUSIONS_2 
        DUPOUT=CMP_ARRANGEMENTS_EXCLUSIONS_2_D NODUPKEY;
BY IRD_NUMBER;
RUN;

DATA ExclTemp.CMP_ARRANGEMENTS_EXCLUSIONS_2; SET CMP_ARRANGEMENTS_EXCLUSIONS_2; RUN;
PROC SORT DATA=EXCLTEMP.CMP_ARRANGEMENTS_EXCLUSIONS_2; BY IRD_NUMBER; RUN;
/*********************************************************************************************************************************/
%drop_edw(arrangements_exclusions);
%drop_edw(arrangements_exclusions_1);
%drop_edw(arrangements_exclusions_1a);
%drop_edw(arrangements_exclusions_1aa);
%drop_edw(arrangements_exclusions_1aaa);
%drop_edw(arrangements_exclusions_1b);
%drop_edw(arrangements_exclusions_1c);
%drop_edw(arrangements_exclusions_1cc);
%drop_edw(arrangements_exclusions_1d);
%drop_edw(arrangements_exclusions_1dd);
%drop_edw(arrangements_exclusions_1e);
/*********************************************************************************************************************************/
%ErrCheck;
/*********************************************************************************************************************************/

