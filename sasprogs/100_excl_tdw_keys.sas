/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 100_excl_tdw_keys.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            From 000_TDW_keys.sas
2015-2019  	Original EXCL development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

PROC SORT DATA=TDW_CURR.TBL_ACCOUNTINFO  (KEEP = IRD_NUMBER ACCOUNT_KEY ACCOUNTTYPE CUSTOMER_KEY ACCOUNT_DOCUMENT_KEY CURRENT_REC_FLAG)  OUT=TBL_ACCOUNTINFO;  BY ACCOUNT_DOCUMENT_KEY; RUN;
PROC SORT DATA=TDW_CURR.TBL_NZACCOUNTSTD (KEEP = IRD_NUMBER HERITAGE_LOCATION_NUMBER ACCOUNT_DOC_KEY CURRENT_REC_FLAG) OUT=TBL_NZACCOUNTSTD; BY ACCOUNT_DOC_KEY; RUN;
/*********************************************************************************************************************************/
DATA ExclWork.TDW_KEYS (DROP=CURRENT_REC_FLAG ACCOUNT_DOCUMENT_KEY) ;
	MERGE   TBL_ACCOUNTINFO  (IN = A) 
			TBL_NZACCOUNTSTD (IN = B RENAME = (ACCOUNT_DOC_KEY = ACCOUNT_DOCUMENT_KEY));
	BY ACCOUNT_DOCUMENT_KEY;
	IF A AND B;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=ExclWork.TDW_KEYS; BY ACCOUNT_KEY; RUN;
PROC SORT DATA=ExclWork.TDW_KEYS NODUPKEY OUT=ExclWork.TDW_KEYS1;BY CUSTOMER_KEY;RUN;
