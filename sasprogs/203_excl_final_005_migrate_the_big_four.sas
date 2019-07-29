/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 203_excl_final_005_migrate_the_big_four.sas

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
%put INFO-203_excl_final_005_migrate_the_big_four.sas: STUB AT PRESENT;
%GetStarted;
%MACRO CLEAN(DS);
proc sql; select "&ds." as dataset, count(irdnumber) as record_count, count(distinct(irdnumber)) as unique_records from excltemp.&ds.; quit;
DATA CAMEXCL.&DS. (ALTER=&AP.);
MERGE EXCLTEMP.&DS. (IN=A) TDW_CURR.SPECIAL_CUSTOMERS (IN=B KEEP=IRD_NUMBER RENAME=(IRD_NUMBER=IRDNUMBER));
BY IRDNUMBER;
IF NOT B;
RUN;
PROC DATASETS LIB=EXCLTEMP NOLIST; DELETE &DS.; RUN;
%MEND;


%CLEAN(ALL_EXCLUSIONS);
%CLEAN(CMP_EXTRA_VARIABLES);
%CLEAN(CMP_PREVIOUS_CAMPAIGN_VARIABLES);
%CLEAN(CMP_LEAD_VARIABLES);

%ErrCheck;

