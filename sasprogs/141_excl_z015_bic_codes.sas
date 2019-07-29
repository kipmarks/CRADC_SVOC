/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z015_bic_codes.sas

Overview:     STUB AT PRESENT - No access to campaign tables
              
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
%put INFO-141_excl_z015_bic_codes.sas: STUB ONLY;
%GetStarted;
/************************************************************************************************************************/
/* Purpose is to bring back the BIC code for each customer 
/* Each non tax type profile could have a different BIC code so brought back profile. 
/* Also NAICS has a business makeup field. I have brought this back though at this point it is not usefull
/* the risk with this point is that in the future customer may be able to have multiple BIC codes per profile
/* START has this functionality though at this point it is not being implemented*
/* If this is ever implement may need an extra data step dropping lower business make ups, is ordered by;
/*  customer_key, profile_number, business_makeup desc
/************************************************************************************************************************/
/*  Richards Tweaks ;-)
/*  I removed the profile number, as not required for now.  An IRD Number can have multiple SIC codes.  Final table
/*  created here aggregates to a single row per customer and includes a variable to indicate multiple codes exist.
/************************************************************************************************************************/


PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1"  PATH=DWP READBUFF=32867 );
CREATE TABLE EXCLTEMP.BIC_CODES AS SELECT * FROM CONNECTION TO MYORACON (
        SELECT C.IRD_NUMBER,
               C.CUSTOMER_KEY,
/*               C.PROFILE_NUMBER,*/
               C.NAICS AS SIC_CODE,
               C.BUSINESS_MAKEUP,
               /*There is a description field in START that does not seem to have come over to TDW. 
               Unsure where this description field is pulling its decode from*/
               B.SIC_GROUPING_LEVEL_1,
               B.SIC_GROUPING_LEVEL_2,
               B.SIC_GROUPING_LEVEL_3,
               B.SIC_GROUPING_LEVEL_4
			   /*As going to be linked to other CRADC info no need for customers current client 
                 status as this will be captured under other viables/exclusions*/
          FROM TDW.TBL_NAICS_VALL                C
     LEFT JOIN "67AWCH".CMP_SIC_CODES_AND_GROUPS B ON C.NAICS = B.SIC_CODE
         WHERE C.CURRENT_REC_FLAG = 'Y' AND
               C.ACTIVE = '1' AND
               C.CEASE_DATE IS NULL);
DISCONNECT FROM MYORACON;
QUIT;

PROC SORT DATA=EXCLTEMP.BIC_CODES NODUPKEY; BY _ALL_; RUN;

DATA EXCLTEMP.BIC_CODES_UNIQUE (KEEP=IRD_NUMBER SIC_CODE SIC_GROUPING_LEVEL_1 SIC_GROUPING_LEVEL_2 SIC_GROUPING_LEVEL_3 SIC_GROUPING_LEVEL_4 MULTIPLE_SIC_CODES);
 SET EXCLTEMP.BIC_CODES;
BY IRD_NUMBER;
IF FIRST.IRD_NUMBER AND LAST.IRD_NUMBER THEN MULTIPLE_SIC_CODES = 'N';
ELSE MULTIPLE_SIC_CODES = 'Y';
IF LAST.IRD_NUMBER THEN OUTPUT;
RUN;

PROC FREQ DATA=EXCLTEMP.BIC_CODES_UNIQUE; TABLE MULTIPLE_SIC_CODES /MISSING; RUN;

%ErrCheck;

