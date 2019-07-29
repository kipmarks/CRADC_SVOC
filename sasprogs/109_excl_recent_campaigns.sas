/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 109_excl_recent_campaigns.sas

Overview:     Recent campaigns - generally 3 months 
              
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
DATA ExclTemp.PREV_CMPS; 
SET ExclTemp.PREV_CMPS; 
BILATERAL = ROUND(BILATERAL,.1); 
RUN;
/*********************************************************************************************************************************/
DATA 	ExclTemp.PREV_CMPS_CS
		ExclTemp.PREV_CMPS_SL
		ExclTemp.PREV_CMPS_CCO
		ExclTemp.PREV_CMPS_B12
		ExclTemp.PREV_CMPS_BAU
		ExclTemp.PREV_CMPS_B12_RTNS
		ExclTemp.PREV_CMPS_B10
        WTF;
SET ExclTemp.PREV_CMPS;
     IF BILATERAL IN(9,10,8.2)     THEN OUTPUT ExclTemp.PREV_CMPS_CS;
ELSE IF BILATERAL IN(5,6)          THEN OUTPUT ExclTemp.PREV_CMPS_SL;
ELSE IF BILATERAL IN(8,8.1)        THEN OUTPUT ExclTemp.PREV_CMPS_CCO;
ELSE IF BILATERAL IN(3,3.1,11)     THEN OUTPUT ExclTemp.PREV_CMPS_B12;
ELSE IF BILATERAL IN(7,7.1)        THEN OUTPUT ExclTemp.PREV_CMPS_BAU;
ELSE IF BILATERAL IN(2,2.1,2.2,4)  THEN OUTPUT ExclTemp.PREV_CMPS_B12_RTNS;
ELSE IF BILATERAL IN(1,1.1)        THEN OUTPUT ExclTemp.PREV_CMPS_B10;
ELSE                                    OUTPUT WTF;
RUN;

proc freq data=wtf;table comm_desc; run;

PROC SORT DATA = ExclTemp.PREV_CMPS;          BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; RUN;
PROC SORT DATA = ExclTemp.PREV_CMPS_CS;       BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; RUN;
PROC SORT DATA = ExclTemp.PREV_CMPS_SL;       BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; RUN;
PROC SORT DATA = ExclTemp.PREV_CMPS_CCO;      BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; RUN;
PROC SORT DATA = ExclTemp.PREV_CMPS_B12;      BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; RUN;
PROC SORT DATA = ExclTemp.PREV_CMPS_BAU;      BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; RUN;
PROC SORT DATA = ExclTemp.PREV_CMPS_B12_RTNS; BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; RUN;
PROC SORT DATA = ExclTemp.PREV_CMPS_B10;      BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; RUN;

DATA ExclTemp.PREV_CMPS_UNIQUE;          SET ExclTemp.PREV_CMPS;          BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; IF FIRST.IRD_NUMBER THEN OUTPUT; RUN;
DATA ExclTemp.PREV_CMPS_UNIQUE_CS;       SET ExclTemp.PREV_CMPS_CS;       BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; IF FIRST.IRD_NUMBER THEN OUTPUT; RUN;
DATA ExclTemp.PREV_CMPS_UNIQUE_SL;       SET ExclTemp.PREV_CMPS_SL;       BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; IF FIRST.IRD_NUMBER THEN OUTPUT; RUN;
DATA ExclTemp.PREV_CMPS_UNIQUE_CCO;      SET ExclTemp.PREV_CMPS_CCO;      BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; IF FIRST.IRD_NUMBER THEN OUTPUT; RUN;
DATA ExclTemp.PREV_CMPS_UNIQUE_B12;      SET ExclTemp.PREV_CMPS_B12;      BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; IF FIRST.IRD_NUMBER THEN OUTPUT; RUN;
DATA ExclTemp.PREV_CMPS_UNIQUE_BAU;      SET ExclTemp.PREV_CMPS_BAU;      BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; IF FIRST.IRD_NUMBER THEN OUTPUT; RUN;
DATA ExclTemp.PREV_CMPS_UNIQUE_B12_RTNS; SET ExclTemp.PREV_CMPS_B12_RTNS; BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; IF FIRST.IRD_NUMBER THEN OUTPUT; RUN;
DATA ExclTemp.PREV_CMPS_UNIQUE_B10;      SET ExclTemp.PREV_CMPS_B10;      BY IRD_NUMBER DESCENDING COMM_END_DATE DESCENDING CASE_NUMBER; IF FIRST.IRD_NUMBER THEN OUTPUT; RUN; 
/*********************************************************************************************************************************/
