/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z019_property_ownership.sas

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
PROC SORT DATA=CAMEXCL.CMP_PROPERTY_OWNERSHIP 
          OUT=ExclWork.CMP_PROPERTY_OWNERSHIP (RENAME=(NBR_PROPERTIES_OWNED = PROPERTYOWNERSHIP)); 
BY IRD_NUMBER; 
RUN;