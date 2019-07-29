/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z003_current_cs_customers.sas

Overview:     STUB ONLY. Needs autocall macro from 
				/data/shared/iic/intel_delivery_resources/sasautos
              
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
%put INFO-141_excl_z0003_current_cs_customers.sas: STUB ONLY;
/**************************************************************************/
data ExclWork.cs (keep=ird_number CurrentNCPCPR);
	set sas_macro_cs_custs;
	if current_cpr_indicator  = 'Y' and CURRENT_NCP_INDICATOR  = 'Y' then CurrentNCPCPR = 'BTH';
		else if current_cpr_indicator  = 'Y' then CurrentNCPCPR = 'CPR';
	else if CURRENT_NCP_INDICATOR = 'Y' then CurrentNCPCPR = 'NCP';
	if CurrentNCPCPR = '' then delete;
run;

PROC SORT DATA=ExclWork.CS; BY IRD_NUMBER; RUN;
