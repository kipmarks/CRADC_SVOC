/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 133_excl_open_corre.sas

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

/************************************************************************************************************************/
/*Bring back incomplete debt-related heritage corry from last 60 days*/
PROC SQL;
CREATE TABLE CMPS_CORRIE_FIRST AS 
        SELECT B.CUSTOMER_KEY,
               A.IRD_NUMBER
          FROM EDW_CURR.CORRESPONDENCE_INBOUND_VALL A
    INNER JOIN TDW_CURR.TBL_CUSTOMER_VALL           B ON A.IRD_NUMBER = B.IRD_NUMBER AND
                                                    B.EFFECTIVE_TO IS NULL
         WHERE A.FUNCTION_CODE = 3
		   AND DATEPART(A.DATE_RECEIVED) > "&eff_date."D - 60 
           AND A.DATE_COMPLETED IS NULL
           AND A.DELETED_INDICATOR = 'N';
quit;
run;
/************************************************************************************************************************/
/*Check for incomplete debt-related Web Notice tasks in START*/
/*Include both R2 and R3 message types*/
PROC SQL;
CREATE TABLE CMPS_CORRIE_START AS 
        SELECT A.CUSTOMER_KEY,
               B.IRD_NUMBER
          FROM TDW_CURR.TBL_TASKOPEN_VALL A
    INNER JOIN TDW_CURR.TBL_CUSTOMER_VALL B ON A.CUSTOMER_KEY = B.CUSTOMER_KEY 
                                      AND B.EFFECTIVE_TO IS NULL
         WHERE A.CURRENT_REC_FLAG = 'Y' AND
               A.TASK_SOURCE = 'NOTICE' AND 
               (A.TASK_TYPE     IN ('NZ.MYBILL','NZ.DEB','NZ.MYB','NZ.INS','NZ.STINAR') OR 
                A.TASK_CATEGORY IN ('NZ.MYBILL','NZ.DEB','NZ.MYB','NZ.INS','NZ.STINAR'));
QUIT;
/************************************************************************************************************************/
DATA EXCLTEMP.CMPS_CORRIE; 
SET CMPS_CORRIE: ; 
RUN;
PROC SORT DATA=EXCLTEMP.CMPS_CORRIE NODUPKEY; 
BY IRD_NUMBER CUSTOMER_KEY; 
RUN;
/************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; 
DELETE CMPS_CORRIE: ; 
RUN;
/************************************************************************************************************************/
