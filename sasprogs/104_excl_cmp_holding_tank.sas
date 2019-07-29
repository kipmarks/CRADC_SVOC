/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 104_excl_cmp_holding_tank.sas

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

/*********************************************************************************************************************************/
/*  Appear in Campaign Holding Tank
/*********************************************************************************************************************************/

/*********************************************************************************************************************************/
DATA ExclTemp.HOLDING_TANK_UNIQUE; 
SET ExclTemp.CMPS_HOLDING_TANK; 
BY IRD_NUMBER EXPIRY_DATE; 
IF LAST.IRD_NUMBER THEN OUTPUT; 
RUN;
/*********************************************************************************************************************************/
