**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 001_cradc_001b_full_edw.sas

Overview:     Full extract of EDW data for CRADC
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

25Jul2019   KM  Made use ofprocessing dates consistent
June2019  	KM  Migration to DIP
            
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      


%GetStarted;
/************************************************************************************************************************/
/*  Table Prep
/*  This step brings in the base data from the EDW tables.
/************************************************************************************************************************/
%LET D=%SYSFUNC(DATETIME());
/************************************************************************************************************************/
DATA edw_curr.CASE_ACTIONS;       SET DSS.CASE_ACTIONS_VALL;      WHERE (LAST_ACTION_INDICATOR = 'Y' OR SEQUENCE_NUMBER = 999) AND 
                                                                        CASE_TYPE_CODE IN('CSR','CN');
RUN;
DATA edw_curr.SPECIAL_CLIENTS;    SET DSS.SPECIAL_CLIENTS;RUN;

DATA edw_curr.ELEMENTS_ALL;       SET DSS.ELEMENTS_VALL;          WHERE DATE_CEASED EQ . AND 
                                                                        CASE_TYPE_CODE IN ('CN','CSR') AND 
                                                                        ELEMENT_TYPE EQ 'C' AND
                                                                        (DATE_END > DATE_START OR DATE_END = .);
RUN;
DATA edw_curr.ELEMENTS;           SET edw_curr.ELEMENTS_ALL;      WHERE DATE_END EQ .; RUN;
DATA edw_curr.CASES_ALL;          SET DSS.CASES_VALL;             WHERE DATE_CEASED EQ . AND 
                                                                        CASE_TYPE_CODE IN ('CN','CSR'); 
RUN;
DATA edw_curr.CASES;              SET edw_curr.CASES_ALL;         WHERE DATE_END EQ . ; RUN;
DATA edw_curr.POLICING_PROFILES;  SET DSS.POLICING_PROFILES_VALL; WHERE DATE_CEASED EQ . AND
                                                                        DATE_FINALISED EQ . AND
                                                                        DATEPART(DATE_ACTUALLY_DUE) LT "&eff_date."D AND
                                                                        FINALISATION_CODE EQ 'XX';
RUN;
DATA edw_curr.TAX_CSA;            SET DSS.TAX_CSA_VALL;           WHERE DATE_CEASED EQ . AND
                                                                        TREG_DATE_END EQ .;
RUN;
DATA edw_curr.CS_ASSESSMENTS;     SET DSS.CS_ASSESSMENTS_VALL;    WHERE DATE_END >= &D. AND
                                                                        DATE_START <= &D. AND
                                                                        ACTIVE_STATUS_INDICATOR = 'A';
RUN;

DATA EDW_CURR.CROSS_REFERENCES;   SET DSS.CROSS_REFERENCES_VALL;  WHERE DATE_CEASED EQ .; RUN;
/************************************************************************************************************************/
/*  Clear the connection to the DSS schema in EDW.
/************************************************************************************************************************/
libname dss clear;
/************************************************************************************************************************/
PROC SORT DATA=edw_curr.SPECIAL_CLIENTS;   BY IRD_NUMBER;                                                     RUN;
PROC SORT DATA=edw_curr.ELEMENTS;          BY CASE_KEY RETURN_PERIOD_DATE;                                    RUN;
PROC SORT DATA=edw_curr.ELEMENTS_ALL;      BY CASE_KEY RETURN_PERIOD_DATE;                                    RUN;
PROC SORT DATA=edw_curr.CASES;             BY CASE_KEY;                                                       RUN;
PROC SORT DATA=edw_curr.CASES_ALL;         BY CASE_KEY;                                                       RUN;
PROC SORT DATA=edw_curr.POLICING_PROFILES; BY IRD_NUMBER LOCATION_NUMBER RETURN_PERIOD_DATE;                  RUN;
PROC SORT DATA=edw_curr.TAX_CSA NODUPKEY;  BY IRD_NUMBER LOCATION_NUMBER TAX_TYPE DESCENDING TREG_DATE_START; RUN;
/************************************************************************************************************************/
/*There are a number of ELEMENTS that show as being still open although the case they relate to are actually closed.
/*  The following code snippet will replace the end date for the element with the end date from the case where required
/************************************************************************************************************************/
 DATA EDW_CURR.ELEMENTS_ALL; 
MERGE EDW_CURR.ELEMENTS_ALL (IN=A)
      EDW_CURR.CASES_ALL    (IN=B KEEP=CASE_KEY DATE_END RENAME=(DATE_END = CASE_DATE_END)); 
BY CASE_KEY; 
IF DATE_END = . AND CASE_DATE_END NE . THEN DO;
    DATE_END = CASE_DATE_END;
    CORRECTED = 'NR';
    END;
ELSE IF DATE_END NE . AND CASE_DATE_END NE . AND DATE_END > CASE_DATE_END THEN DO;
    DATE_END_OLD = DATE_END;
    DATE_END = CASE_DATE_END;
    CORRECTED = 'WD';
    END;

IF A AND B THEN OUTPUT;

RUN;
/************************************************************************************************************************/
DATA edw_curr.CURRENT_ELEMENTS;
 MERGE edw_curr.ELEMENTS (IN=ELEMENT)
       edw_curr.CASES    (IN=CASE   KEEP=ird_number location_number CASE_KEY);
BY CASE_KEY;
/************************************************************************************************************************/
/*If there is an open element AND and open case, then it's a current_element.  There ARE some instances of;
/*  -  Open case but no element(s)
/*  -  Open element(s) but no case
/************************************************************************************************************************/
IF ELEMENT AND CASE THEN output; 
RUN;


/************************************************************************************************************************/
/*  Manipulate CASE_ACTIONS data to extract current state of last/next action data into single record
/************************************************************************************************************************/
DATA CASES (KEEP=CASE_KEY DATE_BEGIN CASE_CATEGORY_CODE); SET EDW_CURR.CASES; RUN;
PROC SORT DATA=edw_curr.CASE_ACTIONS out=case_actions; BY CASE_KEY SEQUENCE_NUMBER; RUN;
PROC SORT DATA=CASES;                                  BY CASE_KEY;                 RUN;

DATA CASE_ACTIONS_LAST 
     CASE_ACTIONS_NEXT;
MERGE CASES        (IN=CASES)
      CASE_ACTIONS (IN=ACTIONS);
      BY CASE_KEY;
IF CASES AND ACTIONS THEN DO;
    IF SEQUENCE_NUMBER NE 999 THEN OUTPUT CASE_ACTIONS_LAST;
    IF SEQUENCE_NUMBER EQ 999 THEN OUTPUT CASE_ACTIONS_NEXT;
    END;
RUN;
/************************************************************************************************************************/
/*  Write out final dataset
/************************************************************************************************************************/
DATA edw_curr.CASE_ACTIONS_CURRENT;
RETAIN IRD_NUMBER LOCATION_NUMBER CASE_TYPE_CODE CASE_CATEGORY_CODE CASE_KEY DATE_BEGIN;
MERGE CASE_ACTIONS_LAST (RENAME =(CASE_ACTION_TYPE_CODE=LAST_CASE_ACTION_TYPE_CODE 
                                  ACTION_DATE=LAST_ACTION_DATE 
                                  MAINFRAME_USER_ID=LAST_MAINFRAME_USER_ID)
                           DROP = LAST_ACTION_INDICATOR NEXT_ACTION_INDICATOR TIMESTAMP STEP_CODE TOTAL_ARREARS_AMOUNT ACTION_CEASED_DATE)
      CASE_ACTIONS_NEXT (RENAME =(CASE_ACTION_TYPE_CODE=NEXT_CASE_ACTION_TYPE_CODE 
                                  ACTION_DATE=NEXT_ACTION_DATE 
                                  MAINFRAME_USER_ID=NEXT_MAINFRAME_USER_ID)
                           KEEP = IRD_NUMBER LOCATION_NUMBER CASE_KEY CASE_NUMBER CASE_TYPE_CODE CASE_ACTION_TYPE_CODE ACTION_DATE MAINFRAME_USER_ID DATE_BEGIN CASE_CATEGORY_CODE);
BY CASE_KEY;
RUN;
/************************************************************************************************************************/
/*  PROC SORT to check for unique records.  Duplicates being writeen to seperate dataset
/************************************************************************************************************************/
PROC SORT DATA=edw_curr.CASE_ACTIONS_CURRENT 
          DUPOUT=CASE_ACTIONS_CURRENT_DUPLICATES
          NODUPKEY; 
          BY IRD_NUMBER LOCATION_NUMBER CASE_TYPE_CODE CASE_CATEGORY_CODE; 
RUN;
/************************************************************************************************************************/
/*  Clean out temp tables
/************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; DELETE CASE_ACTIONS CASES CASE_ACTIONS_LAST CASE_ACTIONS_NEXT; RUN;

%ErrCheck;