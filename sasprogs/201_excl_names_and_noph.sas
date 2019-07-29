/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 201_excl_names_and_noph.sas

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
/*PROC SORT DATA=EXCLWORK.PHONE_NUMBERS OUT=DUPE_PH NOUNIQUEKEY; BY IRD_NUMBER; RUN;*/

DATA EXCLWORK.PHONE_NUMBERS_NAMES(KEEP=IRD_NUMBER LIST_FORMAT_NAME FIRST_NAMES NAME PHONE 
                RENAME=(LIST_FORMAT_NAME=ACCOUNTNAME FIRST_NAMES=FIRSTNAME NAME=LASTNAME));
 SET EXCLWORK.PHONE_NUMBERS;
BY CUSTOMER_KEY;
RETAIN PH_NO ;
IF FIRST.CUSTOMER_KEY THEN PH_NO=0;
IF PHONE_NUMBER EQ WORK_PHONE_NUMBER EQ CELL_PHONE_NUMBER EQ '' THEN PHS = 0;
ELSE PHS = 1;
PH_NO = PH_NO + PHS;
IF PH_NO EQ 0 THEN PHONE = 'N';
ELSE PHONE = 'Y';
IF LAST.CUSTOMER_KEY THEN OUTPUT;
RUN;

DATA EXCLWORK.PHONE_NUMBERS_NAMES;
RETAIN IRD_NUMBER FIRST_NAMES NAME ;
SET EXCLWORK.PHONE_NUMBERS_NAMES;
RUN;

PROC SORT DATA=EXCLWORK.PHONE_NUMBERS_NAMES (WHERE=(IRD_NUMBER NE .)); 
BY IRD_NUMBER; RUN;


