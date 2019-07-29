/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 125_excl_strike_offs.sas

Overview:     STUB ONLY - direct links to Tom Hollman's personal schema. 
              
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
/* REQUIRES ACCESS TO 17THHO.STRUCK_OFF_COMPANIES */
/* THIS TABLE IS UPDATED MONTHLY BY TOM HOLLMAN */
***************************************************************************************************** ;
* 15.        Company (COY) Strike Off 
* added Nov 2011 - source table - AXBX27.CMP_STRIKEOFF (Ajay Bellamy) which is updated monthly.       ;
* added monthly strike-off lists from the coys office - source table TEP1.AA_SO_COY_MATCHED_NOV13 AL4
* updated Feb 2018 Tony Prisk KG																	  ;
* updated for Release 3 Nisha Nair
	*Using TDW customer table to look at non-ceased entities against strike off list from companies   ;
	*This is on the basis that out of 252352 records with a S status in Heritage, only 1869 have a    
	null cease date in START																				  ;
	*Adding a check against presence of a current Insolvency Finalised indicator on the assumption    
    that these translate to L status in Heritage and so wouldnt have been picked by pre-Release3 code 
    This halved the initial mismatch rate.															  ;
    *Once 'ACTIVE' exclusion is ready, can be reviewed to see if using this exclusion datapoint 
    instead of null cease date and INSCLF indicator checks improves accuracy						  ;
    *Checks for the same query using DWT (test) data pulled up some mismatches due to lag between 
    information updated in Production vs Staging environment plus missing DWT data from recent updates 
    in Staging -not sure if this is due to limited loads into DWT during SBS                          ;  
***************************************************************************************************** ;


/*PROC SQL;*/
/*  CREATE TABLE ExclTemp.COY_STRIKEOFF AS */
/*        SELECT A.IRD_NUMBER,*/
/*               A.NAME,*/
/*               A.ID_SERIAL_NUMBER*/
/*          FROM EXCLTEMP.STRUCK_OFF_COMPANIES      A */
/*   INNER  JOIN TDW_CURR.TBL_CUSTOMERINFO B ON A.IRD_NUMBER = B.IRD_NUMBER*/
/*     LEFT JOIN TDW_CURR.TBL_INDICATOR    I ON B.CUSTOMER_KEY = I.CUSTOMER_KEY AND*/
/*                                              I.INDICATOR_FIELD = 'INSCLF' AND*/
/*                                              I.VER = 0 AND*/
/*                                              I.CURRENT_REC_FLAG = 'Y' AND*/
/*                                              I.EFFECTIVE_TO IS NULL AND*/
/*                                              I.ACTIVE = 1 AND*/
/*                                              (I.CEASE IS NULL OR I.CEASE > DATETIME()) AND*/
/*                                              I.COMMENCE IS NOT NULL*/
/*         WHERE B.CURRENT_REC_FLAG = 'Y' AND*/
/*               B.EFFECTIVE_TO IS NULL AND*/
/*               B.CEASE_DATE IS NULL AND*/
/*               I.CUSTOMER_KEY IS NULL;*/
/**/
/*QUIT;*/
/**/
/*proc sort data=ExclTemp.COY_STRIKEOFF dupout=dupes nodupkey; */
/*by ird_number; */
/*run;*/
/**/
/*PROC DATASETS LIB=EXCLTEMP NOLIST; */
/*DELETE STRUCK_OFF_COMPANIES; */
/*RUN;*/

