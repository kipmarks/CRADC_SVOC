/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 100_excl_sasautos.sas

Overview:     Collected sasautos ready for migration to DIP.
              Eventually will separate into one file per macro.
              
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
/*
/*           _____   _    _   _____   _        _____       _____   _    _   _____    _____     ____    _____    _______   
/*          / ____| | |  | | |_   _| | |      |  __ \     / ____| | |  | | |  __ \  |  __ \   / __ \  |  __ \  |__   __|  
/*         | |      | |__| |   | |   | |      | |  | |   | (___   | |  | | | |__) | | |__) | | |  | | | |__) |    | |     
/*         | |      |  __  |   | |   | |      | |  | |    \___ \  | |  | | |  ___/  |  ___/  | |  | | |  _  /     | |     
/*         | |____  | |  | |  _| |_  | |____  | |__| |    ____) | | |__| | | |      | |      | |__| | | | \ \     | |     
/*          \_____| |_|  |_| |_____| |______| |_____/    |_____/   \____/  |_|      |_|       \____/  |_|  \_\    |_|     
/*                                                                                                                        
/*                                                                                                                        
/*                       _____   _    _    _____   _______    ____    __  __   ______   _____     _____                               
/*                      / ____| | |  | |  / ____| |__   __|  / __ \  |  \/  | |  ____| |  __ \   / ____|                              
/*                     | |      | |  | | | (___      | |    | |  | | | \  / | | |__    | |__) | | (___                                
/*                     | |      | |  | |  \___ \     | |    | |  | | | |\/| | |  __|   |  _  /   \___ \                               
/*                     | |____  | |__| |  ____) |    | |    | |__| | | |  | | | |____  | | \ \   ____) |                              
/*                      \_____|  \____/  |_____/     |_|     \____/  |_|  |_| |______| |_|  \_\ |_____/                               
/*                                                                                                                 
/*********************************************************************************************************************************/
/*            Task Name:  cs_customers
/*              Purpose:  Create a table of all child support customers.  Includes those with a current assessment as well as
/*                        those who only have outstanding liability and/or entitlement
/*             Coded By:  Richard Holley
/*              Created:  26 June 2017
/*               Inputs:  out_table =    -=-  This is the name of the final table to be created.  
/*                                            Defaults to: SAS_MACRO_CS_CUSTS
/*                          out_lib =    -=-  The libname of where the final dataset will output to.
/*                                            Defaults to: WORK
/*********************************************************************************************************************************/
/*Example Macro Call(s): %cs_customers;                             [Defaults]
/*                       %cs_customers(OUT_LIB=DATA);               [Default tablename, 'DATA' as the library]
/*                       %cs_customers(OUT_TABLE=CSC);              ['CSC' as the output table, default library]
/*                       %cs_customers(OUT_TABLE=CSC,OUT_LIB=DATA); ['CSC' as the output table, 'DATA' as the library]
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*  Generates a complete list of all customers (NCP and CPR) with an open CS tax type.
/*********************************************************************************************************************************/
%macro cs_customers(out_table = SAS_MACRO_CS_CUSTS,  out_lib = WORK, clean = Y, lvl = VIEW);

     ********* SAS Macro Logging ************;
     %let Macro_Logging_Name = &SYSMACRONAME;
     %_SAS_Macro_Logging(&Macro_Logging_Name);
     ****************************************;

proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1"  path=dwp);
CREATE TABLE &out_lib..SAS_MACRO_TAX_CSA_&lvl. AS SELECT * FROM CONNECTION TO MYORACON (
        SELECT * 
          FROM DSS.TAX_CSA_&lvl. T
         WHERE T.DATE_CEASED IS NULL AND
               T.TREG_DATE_END IS NULL);
/*************************************************************************************************************************/
DISCONNECT FROM MYORACON;
QUIT;
PROC SORT DATA=&out_lib..SAS_MACRO_TAX_CSA_&lvl. NODUPKEY;BY IRD_NUMBER LOCATION_NUMBER TAX_TYPE;RUN;
DATA &out_lib..SAS_MACRO_TAX_CSA_&lvl.;
 SET &out_lib..SAS_MACRO_TAX_CSA_&lvl.;
IF TAX_TYPE = 'CSE' THEN DELETE;
RUN;
TITLE "OPEN TAX TYPES (NCP & CPR)";
PROC SQL; SELECT TAX_TYPE, 
                 COUNT(1) AS CUSTOMERS
            FROM &out_lib..SAS_MACRO_TAX_CSA_&lvl. 
        GROUP BY TAX_TYPE;
QUIT;
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*  Generates a complete list of all customers (NCP and CPR) with a current assessment
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1"  path=dwp);
/*********************************************************************************************************************************/
CREATE TABLE &out_lib..SAS_MACRO_CS_CUST_TEMP1 AS SELECT * FROM CONNECTION TO MYORACON(
        SELECT CS1.IRD_NUMBER,
               CS1.TAX_TYPE
          FROM DSS.CS_ASSESSMENTS_&lvl. CS1         /*LOOKS TO SEE IF THERE IS A CURRENT ASSESSMENT*/
         WHERE CS1.DELETED_INDICATOR = 'N' AND
               CS1.ACTIVE_STATUS_INDICATOR = 'A' AND
               CS1.DATE_START < SYSDATE AND
               CS1.DATE_END > SYSDATE AND
               CS1.CHILD_SUPPORT_AMT > 0);
DISCONNECT FROM MYORACON;
QUIT;
TITLE "CURRENT ASSESSMENTS (NCP & CPR)";
PROC SQL;
    SELECT TAX_TYPE, 
           COUNT(1) AS CUSTOMERS
      FROM &out_lib..SAS_MACRO_CS_CUST_TEMP1 
  GROUP BY TAX_TYPE;
QUIT;
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*  Generates a complete list of all customers (NCP and CPR) with a current debt
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1"  path=dwp);
/*********************************************************************************************************************************/
CREATE TABLE &out_lib..SAS_MACRO_CS_CUST_TEMP2 AS SELECT * FROM CONNECTION TO MYORACON(
        SELECT CS2.IRD_NUMBER,
               CS2.TAX_TYPE
          FROM DSSMART.CS_CURRENT_CASES_&lvl. CS2 /*LOOKS TO SEE IF THERE IS A CURRENT DEBT*/
         WHERE CS2.TAX_TYPE != 'CSE' AND
               CS2.TOTAL_DEBT_AMOUNT > 0);
/*************************************************************************************************************************/
DISCONNECT FROM MYORACON;
QUIT;

TITLE "CURRENT DEBT (NCP & CPR)";
PROC SQL;
    SELECT TAX_TYPE, 
           COUNT(1) AS CUSTOMERS
      FROM &out_lib..SAS_MACRO_CS_CUST_TEMP2 
  GROUP BY TAX_TYPE;
QUIT;

/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*  Generates a complete list of all CPR' with oustanding entitlement
/*********************************************************************************************************************************/
proc sql;
connect to oracle as myoracon (user="&oradw_user1" password="&oradw_pass1"  path=dwp);
CREATE TABLE &out_lib..SAS_MACRO_CS_CUST_TEMP3 AS SELECT * FROM CONNECTION TO MYORACON(
        SELECT 
      DISTINCT CS3.CP_IRD_NUMBER AS IRD_NUMBER,
               'CPR'             AS TAX_TYPE
          FROM DSS.CS_REL_MTH_ASSESSMENTS_&lvl. CS3 /*THIS WILL IDENTIFY THOSE CPR'S WHO HAVE OUTSTANDING ENTITLEMENT*/
          JOIN DSSMART.CS_CURRENT_CASES_&lvl.   CCC ON CS3.NCP_IRD_NUMBER = CCC.IRD_NUMBER AND
                                                      CCC.TAX_TYPE = 'NCP'
         WHERE CS3.DATE_CEASED IS NULL AND
               CS3.UNPAID_BALANCE_AMT >= 1);
/*************************************************************************************************************************/
DISCONNECT FROM MYORACON;
QUIT;

TITLE "OUTSTANDING ENTITLEMENT (CPR)";
PROC SQL;
    SELECT TAX_TYPE, 
           COUNT(1) AS CUSTOMERS
      FROM &out_lib..SAS_MACRO_CS_CUST_TEMP3 
  GROUP BY TAX_TYPE;
QUIT;


/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*  Generates a complete list of all cs customer where there is;
/*   - A current assessment (NCP or CPR)
/*   - A current debt (NCP or CPR)
/*   - Outstanding entitlement (CPR)
/*  This list will be filtered later, against the list of customers with an open CS tax type)
/*********************************************************************************************************************************/
proc sql;
        CREATE TABLE &out_lib..SAS_MACRO_CS_CUST_TEMP4 AS
                SELECT IRD_NUMBER, TAX_TYPE, MAX(CURRENT_CS) AS CURRENT_CS
                  FROM (SELECT IRD_NUMBER, TAX_TYPE, 'Y' AS CURRENT_CS FROM &out_lib..SAS_MACRO_CS_CUST_TEMP1     UNION
                        SELECT IRD_NUMBER, TAX_TYPE, 'N' AS CURRENT_CS FROM &out_lib..SAS_MACRO_CS_CUST_TEMP2     UNION
                        SELECT IRD_NUMBER, TAX_TYPE, 'N' AS CURRENT_CS FROM &out_lib..SAS_MACRO_CS_CUST_TEMP3)
              GROUP BY IRD_NUMBER, TAX_TYPE;
quit;



/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*  Pull it all together, along with the check for an open tax type, to produce the final table.
/*********************************************************************************************************************************/
proc sql;
   CREATE TABLE &out_lib..&out_table. AS
        SELECT B.IRD_NUMBER,
               MAX(CASE WHEN T.TAX_TYPE = 'CPR' THEN 'Y' ELSE 'N' END)          AS CPR_INDICATOR,
               MAX(CASE WHEN T.TAX_TYPE = 'NCP' THEN 'Y' ELSE 'N' END)          AS NCP_INDICATOR,
               MAX(CASE WHEN T.TAX_TYPE = 'CPR' THEN CURRENT_CS ELSE 'N' END)   AS CURRENT_CPR_INDICATOR,
               MAX(CASE WHEN T.TAX_TYPE = 'NCP' THEN CURRENT_CS ELSE 'N' END)   AS CURRENT_NCP_INDICATOR,
               MAX(CURRENT_CS)                                                  AS CURRENT_CS
          FROM &out_lib..SAS_MACRO_TAX_CSA_&lvl.  T
          JOIN &out_lib..SAS_MACRO_CS_CUST_TEMP4 B ON B.IRD_NUMBER = T.IRD_NUMBER AND
                                                      B.TAX_TYPE = T.TAX_TYPE AND
                                                      T.DATE_CEASED IS NULL AND
                                                      T.TREG_DATE_END IS NULL
      GROUP BY B.IRD_NUMBER;

/*************************************************************************************************************************/
QUIT;

/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*  Quick, final, summary
/*********************************************************************************************************************************/
TITLE "Total CS Customers (All)";
PROC FREQ DATA=&out_lib..&out_table.; 
TABLES CPR_INDICATOR * NCP_INDICATOR                 /NOCOL NOCUM NOPERCENT NOROW format=comma12.0;
RUN;

TITLE "Total CS Customers (With Current)";
PROC FREQ DATA=&out_lib..&out_table.; 
TABLES CURRENT_CPR_INDICATOR * CURRENT_NCP_INDICATOR /NOCOL NOCUM NOPERCENT NOROW format=comma12.0;
RUN;
/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*  Clean up the temp tables
/*********************************************************************************************************************************/
%if %upcase(&clean) = Y %then %do;
    PROC DATASETS LIB=&out_lib. NOLIST;
    DELETE SAS_MACRO_TAX_CSA_&lvl.
           SAS_MACRO_CS_CUST_TEMP1
           SAS_MACRO_CS_CUST_TEMP2
           SAS_MACRO_CS_CUST_TEMP3
           SAS_MACRO_CS_CUST_TEMP4;
    RUN;
%END;

/*********************************************************************************************************************************/
/*********************************************************************************************************************************/
/*  And, that's it.  We're done.  ;-)
/*********************************************************************************************************************************/
%MEND cs_customers;
