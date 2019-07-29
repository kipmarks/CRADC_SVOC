/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 004_cradc_age_of_elements.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            Original module was 09_Age_Of_Elements.sas
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/************************************************************************************************************************/
/*  Generate the data on the oldest/youngest debt elements
/************************************************************************************************************************/
proc sql;
CREATE TABLE CradcWrk.AGE_OF_ELEMENTS AS
   SELECT IRD_NUMBER, 
          LOCATION_NUMBER, 
          CASE_TYPE,
          ACCOUNT_TYPE_ORIGINAL                AS TAX_TYPE, 
          (MIN(DATE_START)) FORMAT=DATETIME20. AS EARLIEST_ELEMENT_START_DATE, 
          (MAX(DATE_START)) FORMAT=DATETIME20. AS LATEST_ELEMENT_START_DATE,
          (SUM(BALANCE_AMOUNT))                AS DEBT_BALANCE_AMOUNT
      FROM CradcWrk.SS_DEBT
  GROUP BY IRD_NUMBER,
           LOCATION_NUMBER,
           CASE_TYPE,
           ACCOUNT_TYPE_ORIGINAL;
QUIT;


PROC SQL;
  CREATE TABLE CradcWrk.AGE_OF_ELEMENTS_SUMM AS
        SELECT IRD_NUMBER,
               LOCATION_NUMBER,
               MIN(CASE WHEN CASE_TYPE = 'CN' THEN EARLIEST_ELEMENT_START_DATE END) AS OLDEST_ELEMENT_START_DATE_CN  FORMAT=DATETIME20.,
               MAX(CASE WHEN CASE_TYPE = 'CN' THEN LATEST_ELEMENT_START_DATE   END) AS LATEST_ELEMENT_START_DATE_CN  FORMAT=DATETIME20.,
               MIN(CASE WHEN TAX_TYPE = 'CPR' THEN EARLIEST_ELEMENT_START_DATE END) AS OLDEST_ELEMENT_START_DATE_CPR FORMAT=DATETIME20.,
               MAX(CASE WHEN TAX_TYPE = 'CPR' THEN LATEST_ELEMENT_START_DATE   END) AS LATEST_ELEMENT_START_DATE_CPR FORMAT=DATETIME20.,
               MIN(CASE WHEN TAX_TYPE = 'CSE' THEN EARLIEST_ELEMENT_START_DATE END) AS OLDEST_ELEMENT_START_DATE_CSE FORMAT=DATETIME20.,
               MAX(CASE WHEN TAX_TYPE = 'CSE' THEN LATEST_ELEMENT_START_DATE   END) AS LATEST_ELEMENT_START_DATE_CSE FORMAT=DATETIME20.,
               MIN(CASE WHEN TAX_TYPE = 'NCP' THEN EARLIEST_ELEMENT_START_DATE END) AS OLDEST_ELEMENT_START_DATE_NCP FORMAT=DATETIME20.,
               MAX(CASE WHEN TAX_TYPE = 'NCP' THEN LATEST_ELEMENT_START_DATE   END) AS LATEST_ELEMENT_START_DATE_NCP FORMAT=DATETIME20.
          FROM CradcWrk.AGE_OF_ELEMENTS
      GROUP BY IRD_NUMBER,
               LOCATION_NUMBER;
QUIT;

PROC SORT DATA=CradcWrk.AGE_OF_ELEMENTS_SUMM; BY IRD_NUMBER LOCATION_NUMBER; RUN;

