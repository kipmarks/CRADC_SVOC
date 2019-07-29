/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 010_cradc_case_actions.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            Original module was 16_Case_Actions.sas
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/
/************************************************************************************************************************/
/*  Macro that adds suffix to variables
/*  Adapted from http://support.sas.com/kb/37/433.html
/*  >>>>>> Should be re-written to use proc datasets, saving a dataset re-write. */
/************************************************************************************************************************/
%macro add_suffix(dsn,chr,out);                                                                                                               
   %let dsid=%sysfunc(open(&dsn));                                                                                                        
   %let n=%sysfunc(attrn(&dsid,nvars));                                                                                                 
   data &out;                                                                                                                            
      set &dsn(rename=(                                                                                                                    
      %do i = 3 %to &n;         /* Don't rename ird_number match key */                                                                                                        
         %let var=%sysfunc(varname(&dsid,&i));                                                                                            
         &var=&var&chr
      %end;));                                                                                                                            
      %let rc=%sysfunc(close(&dsid));                                                                                                        
   run;
PROC SORT DATA=&out; BY IRD_NUMBER LOCATION_NUMBER; RUN; 
%mend add_suffix; 
/*******************************************************************/
DATA CradcWrk.ACTIONS_LAST_NEXT_P1_CN  (DROP=DATE_BEGIN CASE_KEY CASE_NUMBER CASE_TYPE CASE_TYPE_CODE LAST_MAINFRAME_USER_ID NEXT_MAINFRAME_USER_ID SEQUENCE_NUMBER CASE_CATEGORY_CODE)
     CradcWrk.ACTIONS_LAST_NEXT_P1_CPR (DROP=DATE_BEGIN CASE_KEY CASE_NUMBER CASE_TYPE CASE_TYPE_CODE LAST_MAINFRAME_USER_ID NEXT_MAINFRAME_USER_ID SEQUENCE_NUMBER CASE_CATEGORY_CODE)
     CradcWrk.ACTIONS_LAST_NEXT_P1_CSE (DROP=DATE_BEGIN CASE_KEY CASE_NUMBER CASE_TYPE CASE_TYPE_CODE LAST_MAINFRAME_USER_ID NEXT_MAINFRAME_USER_ID SEQUENCE_NUMBER CASE_CATEGORY_CODE)
     CradcWrk.ACTIONS_LAST_NEXT_P1_NCP (DROP=DATE_BEGIN CASE_KEY CASE_NUMBER CASE_TYPE CASE_TYPE_CODE LAST_MAINFRAME_USER_ID NEXT_MAINFRAME_USER_ID SEQUENCE_NUMBER CASE_CATEGORY_CODE);
RETAIN IRD_NUMBER LOCATION_NUMBER LAST_CASE_ACTION_TYPE_CODE NEXT_CASE_ACTION_TYPE_CODE LAST_ACTION_DATE NEXT_ACTION_DATE;
LENGTH CASE_TYPE $3.;
 SET EDW_CURR.CASE_ACTIONS_CURRENT;
     IF CASE_TYPE_CODE = 'CN'                                 THEN CASE_TYPE = 'CN';
ELSE IF CASE_CATEGORY_CODE IN ('10','11','12','20','21','22') THEN CASE_TYPE = 'CSE';
ELSE IF CASE_CATEGORY_CODE IN ('30','31','32')                THEN CASE_TYPE = 'NCP';
ELSE IF CASE_CATEGORY_CODE IN ('40','41','42')                THEN CASE_TYPE = 'CPR';

IF CASE_TYPE = 'CN'  THEN OUTPUT CradcWrk.ACTIONS_LAST_NEXT_P1_CN;
IF CASE_TYPE = 'CPR' THEN OUTPUT CradcWrk.ACTIONS_LAST_NEXT_P1_CPR;
IF CASE_TYPE = 'CSE' THEN OUTPUT CradcWrk.ACTIONS_LAST_NEXT_P1_CSE;
IF CASE_TYPE = 'NCP' THEN OUTPUT CradcWrk.ACTIONS_LAST_NEXT_P1_NCP;

RUN;
%add_suffix(CradcWrk.ACTIONS_LAST_NEXT_P1_CN,  _CN,  CradcWrk.ACTIONS_LAST_NEXT_P1_CN);
%add_suffix(CradcWrk.ACTIONS_LAST_NEXT_P1_CPR, _CPR, CradcWrk.ACTIONS_LAST_NEXT_P1_CPR);
%add_suffix(CradcWrk.ACTIONS_LAST_NEXT_P1_CSE, _CSE, CradcWrk.ACTIONS_LAST_NEXT_P1_CSE);
%add_suffix(CradcWrk.ACTIONS_LAST_NEXT_P1_NCP, _NCP, CradcWrk.ACTIONS_LAST_NEXT_P1_NCP);

DATA CradcWrk.ACTIONS_LAST_NEXT;
 MERGE CradcWrk.ACTIONS_LAST_NEXT_P1_CN
       CradcWrk.ACTIONS_LAST_NEXT_P1_CPR
       CradcWrk.ACTIONS_LAST_NEXT_P1_CSE
       CradcWrk.ACTIONS_LAST_NEXT_P1_NCP;
BY IRD_NUMBER LOCATION_NUMBER;
RUN;


PROC DATASETS LIB=CradcWrk NOLIST; DELETE ACTIONS_LAST_NEXT_P1_CN ACTIONS_LAST_NEXT_P1_CPR ACTIONS_LAST_NEXT_P1_CSE ACTIONS_LAST_NEXT_P1_NCP; RUN; QUIT;
