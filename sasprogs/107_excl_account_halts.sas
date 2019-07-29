/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 107_excl_account_halts.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            Initial PROC SQL migrated from ORACLE SQL to SAS PROC SQL
2015-2019  	Original EXCL development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/
/*data _null_;*/
/*d1="01JAN2018"D;*/
/*d2="04JAN2019"D;*/
/*diff=intck('MONTH',d1,d2,'DISCRETE');*/
/*put d1= date9. d2= date9. diff=;*/
/*run;*/

/*********************************************************************************************************************************/
/*  Account Halts                                                                                 ;
/*********************************************************************************************************************************/
/* FIRST account halts cannot be added for more than 12 months */
PROC SQL;
		CREATE TABLE AC_HALTS AS 
		SELECT DISTINCT IRD_NUMBER 
		FROM EDW_CURR.ACCOUNT_HALTS
         WHERE DATE_CEASED IS NULL AND
               HALT_STATUS_INDICATOR = 'A' AND
               DATEPART(DATE_HALT_END) > "&eff_date."D AND
               DATE_HALT_END IS NOT NULL AND
               TAX_TYPE <> 'GST' AND
               INTCK('MONTH',
                     DATEPART(DATE_HALT_START),
                     DATEPART(DATE_HALT_END),
                     'DISCRETE') BETWEEN 0 AND 13;
QUIT;
/*********************************************************************************************************************************/
DATA START_HALTS (KEEP=IRD_NUMBER);
SET TDW_CURR.TBL_INDICATOR (WHERE=(INDICATOR_FIELD = 'ACCHLT' AND 
                                   VER = 0 AND 
                                   CURRENT_REC_FLAG = 'Y' AND 
                                   COMMENCE NE . AND 
                                  (CEASE =. OR DATEPART(CEASE) > "&SYSDATE."D)));
IF DATEPART(COMMENCE)>INTNX('MONTH',TODAY(),-96);
RUN;
/*********************************************************************************************************************************/
DATA ExclTemp.AC_HALTS;
 SET AC_HALTS START_HALTS;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=ExclTemp.AC_HALTS NODUPKEY; BY IRD_NUMBER; RUN;
PROC DATASETS LIB=WORK NOLIST; DELETE AC_HALTS START_HALTS; RUN;
/*********************************************************************************************************************************/