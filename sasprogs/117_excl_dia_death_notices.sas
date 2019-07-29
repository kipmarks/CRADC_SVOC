/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 117_excl_dia_death_notices.sas

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
proc sort data=CamExcl.DIA_DEATH_NOTICE 
           OUT=ExclWork.DIA_DEATH_NOTICE; 
BY IRD_NUMBER; 
RUN;
