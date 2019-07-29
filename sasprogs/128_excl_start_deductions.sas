/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 128_excl_start_deductions.sas

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
/* code provided by Caleb Grove
/*********************************************************************************************************************************/
/*START Deductions Code 19Feb18
/*Deduction base population - active deductions in the either the issued or defaulting stage
/*Compliance is assessed similar to arrangements, so if they missed 3 payments (3 strikes) then they are considered not 
/*  adhering
/*We are aware that the Strikes just continue accumalting and do not make the deduction fail
/*There are data quality (or more START Process quality) concerns with the START deductions
/*********************************************************************************************************************************/
/*R3 Update 01Apr19 CG
/*Auto Deductions should come through into the data the same as officer deductons - no changes needed
/*We've requested the Automated flag for garnish attributes - alternatively can do Who = batch
/*Future Issue Deductions are more difficult - They come through as "NEW" stage until "ISSUED"
/*There is Future Issue Date field in NZS we can use to identify these deductions
/*Waiting to get both Automatic and Future Issue Date into the Garnish Attributes table
/*Currently only "ISSUED" or "DEFLT" deductions appear in garnish details which has the compliance info (Strikes)
/*We decided for R2 not to include "NEW" deductions so will continue with that decision for the interim
/*Currently there deductions with the stage "NEW" which have not been issued and we do not do anythig with
/*Future Issue would be something like "NEW" and Work Date > Today or Created > Today
/*Glen Forwarded an email with all the business rules around how Future Issue Decutions will work
/*See FCR BFD #84120 - Definition 84120
/*After R3 we can decide what we want to do with these customers (it's only a 30 day window)
/*We do not understand how CNVPND will be policed (Converted Deductions)
/*********************************************************************************************************************************/
/*Post R3 07May19 CG
/*Have added in the Automatic and Future Issue Deduction variables
/*Once these populate we can decide how we want these to be built into the process
/*Still unclear how STAGE = 'CNVPND' will work and if this will just move onto the next Stage
/*********************************************************************************************************************************/

DATA TBL_GARNISHTOPBI;
SET TDW_CURR.TBL_GARNISHTOPBI_VALL( KEEP=GARNISH_KEY ACCOUNT_KEY CURRENT_REC_FLAG 
                               WHERE=(CURRENT_REC_FLAG = 'Y'));
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=TDW_CURR.TBL_GARNISH_VALL           (WHERE=(CURRENT_REC_FLAG = 'Y')) 
	OUT=TBL_GARNISH;           
	BY GARNISH_KEY; 
RUN;

PROC SORT DATA=TDW_CURR.TBL_NZ_GARNISHDETAILS_VALL (WHERE=(CURRENT_REC_FLAG = 'Y')) 
	OUT=TBL_NZ_GARNISHDETAILS; 
	BY GARNISH_KEY; 
RUN;

PROC SORT DATA=TBL_GARNISHTOPBI NODUPKEY; 
BY GARNISH_KEY; 
RUN;

PROC SORT DATA=TDW_CURR.TBL_NZ_GARNISHATTRIBUT_VALL (WHERE=(CURRENT_REC_FLAG ='Y')) 
	OUT=TBL_NZ_GARNISHATTRIBUT;
	BY DOC_KEY; 
RUN;
/*********************************************************************************************************************************/
DATA GARNISH (DROP=VER STAGE CLOSED_DATE);
	MERGE 	TBL_GARNISH (IN=A KEEP=IRD_NUMBER CUSTOMER_KEY DOC_KEY GARNISH_KEY GARNISH_TYPE GARNISHID FOLDER_KEY 
									INDICATOR_KEY OWNER CREATED CREATED_WHO CLOSED_DATE STAGE VER 
					   WHERE=(VER =0 AND CLOSED_DATE IS MISSING AND STAGE IN ('ISSUED', 'DEFLT')) ) 
		  	TBL_GARNISHTOPBI (IN=B KEEP=GARNISH_KEY ACCOUNT_KEY)
		  	TBL_NZ_GARNISHDETAILS (IN=C KEEP=GARNISH_KEY EXPECTED_AMOUNT NEXT_EVALUTION_DATE STRIKES VER WHERE=(VER =0));
	BY GARNISH_KEY;
	IF A AND B;
	IF STRIKES <3 THEN GOOD_DEDUCT = 1;
	ELSE GOOD_DEDUCT =0;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=GARNISH;  
	BY ACCOUNT_KEY; 
RUN;

PROC SORT DATA=ExclWork.TDW_KEYS; 
	BY ACCOUNT_KEY; 
RUN;
/*********************************************************************************************************************************/
DATA START_DEDUCT_BUILD1;
	SET GARNISH  (IN=A) 
        ExclWork.TDW_KEYS (IN=B);
	BY ACCOUNT_KEY;
IF A;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=START_DEDUCT_BUILD1; 
	BY DOC_KEY; 
RUN;
/*********************************************************************************************************************************/
/*Bringing through Automatic and Future Issue Deductions which are new R3 START deductions features*/
/*********************************************************************************************************************************/
DATA START_DEDUCT_BUILD1;
	MERGE	START_DEDUCT_BUILD1 (IN=A)
			TBL_NZ_GARNISHATTRIBUT (IN=B KEEP=DOC_KEY AUTOMATIC FUTURE_ISSUE_DATE 
                                              CURRENT_REC_FLAG
									WHERE=(CURRENT_REC_FLAG='Y'));
	BY DOC_KEY;
	IF A;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=START_DEDUCT_BUILD1 NODUPKEY; 
	BY IRD_NUMBER; 
RUN;
/*********************************************************************************************************************************/
/*A SMALL AMOUNT OF CUSTOMERS HAVE MORE THAN 1 ACTIVE DEDUCTION, SO WE NEED TO KNOW HOW MANY THEY AHVE SO WE CAN CHECK 
/*  THEY ADHERING TO THEM ALL THEY NEED BE ADHERING TO BOTH DEDUCTIONS TO GET AN OVERALL ADHERING = Y FLAG
/*********************************************************************************************************************************/
PROC SQL; 
  CREATE TABLE START_DEDUCT_BUILD2 AS
        SELECT A.IRD_NUMBER,
               A.CUSTOMER_KEY,
               A.HERITAGE_LOCATION_NUMBER AS LOCATION_NUMBER,
               COUNT(DISTINCT GARNISH_KEY) AS NBR_OF_DEDUCT,
               SUM(A.GOOD_DEDUCT) AS NBR_GOOD_DEDUCT
          FROM START_DEDUCT_BUILD1 A
      GROUP BY A.IRD_NUMBER,
               A.CUSTOMER_KEY,
               A.HERITAGE_LOCATION_NUMBER;

QUIT;
/*********************************************************************************************************************************/
/*CUSTOMER NEEDS TO HAVE THE SAME AMOUNT OF ADHERING DEDUCTIONS AS THEY DO TOTAL DEDUCTIONS TO GET A Y FLAG FOR ADHERENCE
/*********************************************************************************************************************************/
PROC SQL;
  CREATE TABLE START_DEDUCT_BUILD3 AS
        SELECT A.IRD_NUMBER,
               A.HERITAGE_LOCATION_NUMBER AS LOCATION_NUMBER,
               A.CUSTOMER_KEY,
               A.STRIKES,
               B.NBR_OF_DEDUCT,
               B.NBR_GOOD_DEDUCT,
               CASE WHEN B.NBR_OF_DEDUCT > B.NBR_GOOD_DEDUCT THEN 'N' 
                    WHEN B.NBR_OF_DEDUCT = B.NBR_GOOD_DEDUCT THEN 'Y'
                    ELSE '???' END AS STARTDEDUCTADHERE
          FROM START_DEDUCT_BUILD1 A
    INNER JOIN START_DEDUCT_BUILD2 B ON A.IRD_NUMBER = B.IRD_NUMBER AND
                                        A.CUSTOMER_KEY = B.CUSTOMER_KEY AND
                                        A.HERITAGE_LOCATION_NUMBER = B.LOCATION_NUMBER;
QUIT;
/************************************************************************************************************************/
PROC SORT DATA=START_DEDUCT_BUILD3; 
BY IRD_NUMBER LOCATION_NUMBER DESCENDING STRIKES; 
RUN;
/************************************************************************************************************************/
DATA EXCLTEMP.START_DEDUCTIONS (KEEP=IRD_NUMBER LOCATION_NUMBER STARTDEDUCTADHERE);
 SET START_DEDUCT_BUILD3;
BY IRD_NUMBER CUSTOMER_KEY LOCATION_NUMBER;
IF FIRST.IRD_NUMBER THEN OUTPUT;
RUN;
/************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST;
DELETE
TBL_GARNISHTOPBI TBL_GARNISH TBL_NZ_GARNISHDETAILS GARNISH START_DEDUCT_BUILD1 START_DEDUCT_BUILD2 START_DEDUCT_BUILD3;
RUN;
/************************************************************************************************************************/
