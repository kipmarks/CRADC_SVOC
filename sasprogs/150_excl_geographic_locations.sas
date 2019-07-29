/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 150_excl_geographic_locations.sas

Overview:     STUB ONLY AT PRESENT - No access to tables/views in schema SXT4
              
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
%put INFO-150_excl_geographic_locations.sas: STUB ONLY;
/*Geo from Stu's table - based on post code, so not perfect*/
PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP);
CREATE TABLE ExclWork.GEO AS SELECT * FROM CONNECTION TO MYORACON (
        SELECT A.IRD_NUMBER,
               B.SITE       AS GEO,
               B.SUBREGION  AS GEOSUBREGION
          FROM TDW.TBL_ADDRESSRECORD_VIEW A
    INNER JOIN SXT4.SXT4_CCOMGEOCODE      B ON A.ZIP = B.POSTCODE
         WHERE ADDRESS_TYPE = 'LOC' AND
               COUNTRY = 'NEZ' AND
               CURRENT_REC_FLAG = 'Y' AND
               CURRENT_FLAG = 1 AND
               ACTIVE = 1 AND
               ADDRESS_EFFECTIVE_TO IS NULL AND
               VER = 0);
DISCONNECT FROM MYORACON;
QUIT;

PROC SORT DATA=ExclWork.GEO NODUPKEY; BY IRD_NUMBER; RUN;
