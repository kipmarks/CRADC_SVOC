/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 0013_cradc_test_compare.sas

Overview:     Compares output so far with the saved subset.
              
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

proc compare base=cradc.cradc_svoc_subset 
             compare=cradc.cradc_svoc criterion=0.01;
run;

%put CRADC test ends: %SYSFUNC(TIME(),time8.0);
