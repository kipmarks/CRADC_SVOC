/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z037_valid_address_indicator.sas

Overview:     STUB AT PRESENT
              
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
%put INFO-141_excl_z037_valid_address_indicator.sas: STUB AT PRESENT;
%GetStarted;
DATA ExclWork.VALID_ADDRESS (KEEP=IRD_NUMBER CUSTOMER_KEY VALIDADDRESSINDICATOR);
 SET TDW.TBL_ADDRESSRECORD_VALL (WHERE=(IRD_NUMBER NE . AND ADDRESS_EFFECTIVE_TO IS NULL AND ACTIVE = 1 AND CURRENT_FLAG = 1 AND CURRENT_REC_FLAG = 'Y'));
 VALIDADDRESSINDICATOR = 'Y';
 RUN;
PROC SORT DATA=ExclWork.VALID_ADDRESS NODUPKEY; BY IRD_NUMBER; RUN;
%ErrCheck;

