/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 103_excl_cmp_control.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            From 003_Control.sas.
             
2015-2019  	Original EXCL development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/*********************************************************************************************************************************/
/*Appear in previous campaign control groups
/*********************************************************************************************************************************/
/*  CAMPAIGN CROSSOVERS
/*  The following 3 codes will highlight those customers that are in the control group, have been in recent campaigns,  or in the 
/*  holding tank.  The standard is to not contact them within 3 months but this can be changed if necessary by altering the date 
/*  parameter.  Note that this code does not actually check if the customer had a contact, it only looks at those that were 
/*  included in the campaign.  Once we get better contact info, this can be amended.  
/*  This code is also in the queries\new_campaigns folder  
/*********************************************************************************************************************************/

/*********************************************************************************************************************************/
PROC SORT DATA=EXCLTEMP.CMPS_CNTRL; 
BY IRD_NUMBER; 
RUN;
/*********************************************************************************************************************************/
