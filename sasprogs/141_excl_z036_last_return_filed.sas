/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z036_last_return_filed.sas

Overview:     
              
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

/*********************************************************************************************************************************/
/* Orginal ORACLE query was pretty ugly, using a CTE (common table expression) */
/* and the ROW_NUMBER function and a join to TBL_NZ_RTNATTRIBUTES_VALL */
/* I might be horribly wrong, but seems much easier in SAS */
data main_query(keep=ird_number accgrp filing_period received_date dd);
	set TDW_CURR.TBL_RETURN_VALL(where=(VER = 0
                                        AND CURRENT_REC_FLAG = 'Y'
                                        AND DATEPART(RECEIVED_DATE) <= "&eff_date."D
                                        AND DATEPART(RECEIVED_DATE) > .));
    IF ACCOUNT_TYPE IN  ('GST','GSD') then accgrp='GST';
	ELSE IF ACCOUNT_TYPE IN  ('PSO') then accgrp='PAY';
	ELSE IF ACCOUNT_TYPE IN  ('IIT','ITN') then accgrp='INC';
	ELSE accgrp='OTH';
	dd="&eff_date."D - DATEPART(RECEIVED_DATE);
RUN;

PROC SQL;
  CREATE TABLE main_query2  AS
  SELECT IRD_NUMBER,
         accgrp, 
         MIN(dd) AS dd 
  FROM main_query
  GROUP BY ird_number, accgrp;
QUIT;

proc transpose data=main_query2
               out=main_query3(drop=_name_) suffix=LRF;
	var dd;
	id accgrp;
	by ird_number;
run;

DATA ExclWork.LAST_RETURN_FILED;
SET main_query3;
ARRAY X {*} _NUMERIC_;
LASTRETURNFILED = MIN(OF X[*]);
IF LASTRETURNFILED >= 999999 THEN LASTRETURNFILED = '.';
RUN;


/*********************************************************************************************************************************/
PROC SORT DATA=ExclWork.LAST_RETURN_FILED; 
BY IRD_NUMBER; 
RUN;

/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; 
DELETE LAST_RTN_FILED_START;
DELETE main_query main_query2 main_query3; 
RUN;

