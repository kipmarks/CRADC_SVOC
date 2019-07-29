/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z029_age_of_last_heritage_action.sas

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
/*removed location_number and case_number*/
PROC SQL;

CREATE TABLE AGEOFLASTACTIONHERITAGE AS 
        SELECT IRD_NUMBER,
               MAX(CASE WHEN SEQUENCE_NUMBER ~= 999 THEN ACTION_DATE END) AS LAST_ACTION_DATE, /*LIFTED FROM EXISTING STEP 1*/
               MAX(CASE WHEN SEQUENCE_NUMBER ~= 999 THEN CASE_ACTION_TYPE_CODE END) AS LAST_ACTION_CODE
          FROM edw_curr.CUR_DEBT_CASES_OUTSTANDING_VA
      GROUP BY IRD_NUMBER
      ORDER BY IRD_NUMBER;
QUIT;
RUN;

/*VARIABLE OF INTEREST IS CREATED HERE*/
DATA ExclWork.AGEOFLASTACTIONHERITAGE (DROP=LAST_ACTION_CODE LAST_ACTION_DATE);
 SET WORK.AGEOFLASTACTIONHERITAGE;
IF LAST_ACTION_CODE = "" THEN DELETE; /*GRABS SOME BLANKS WHERE THERE WAS NO LAST ACTION - ONLY NEXT - DELETE THOSE*/
AGEOFLASTACTIONHERITAGE = TODAY() - DATEPART(LAST_ACTION_DATE);/*ACTUAL VARIABLE OF INTEREST AS DIFFERENCE BETWEEN TODAY AND LAST ACTION DATE*/
RUN; 

