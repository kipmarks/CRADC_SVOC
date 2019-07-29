/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z034_active_trading.sas

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


/* An ACTIVE_TRADING customer is someone who is PAYE registered, */
/* or has filed a GST return in the last 6 months with income or expenses in it*/
PROC SQL;
CREATE TABLE ACTIVE_TRADING AS 
        SELECT CASE WHEN GST_RETURN_FILED_IRD = . THEN PAYE_REGISTERED_IRD
                    ELSE GST_RETURN_FILED_IRD END AS IRD_NUMBER,
               'Y' AS ACTIVE_TRADING /*ONLY ACTIVELY TRADING CUSTOMERS HAVE BEEN BROUGHT THROUGH*/
          FROM (/*TDW IN CASE PAYE REGISTRATIONS APPEAR HERE AFTER R3, I HAVE BEEN TOLD THEY WON'T, BUT JUST IN CASE*/
                SELECT PAYE.IRD_NUMBER AS PAYE_REGISTERED_IRD,
                       .            AS GST_RETURN_FILED_IRD,
                       .            AS LATEST_POSTED_DATE
                  FROM TDW_CURR.TBL_ACCOUNT_VALL PAYE
                 WHERE PAYE.CEASE = . AND
                       CURRENT_REC_FLAG = 'Y' AND
                       PAYE.STATUS = 'ACT' AND
                       PAYE.ACCOUNT_TYPE = 'PAY'
                 UNION
                 /*APPARENTLY PAYE REGISTRATIONS WILL STILL BE UPDATED IN THIS TABLE AFTER R3*/
                 SELECT PAYE.IRD_NUMBER AS PAYE_REGISTERED_IRD,
                        .            AS GST_RETURN_FILED_IRD,
                        .            AS LATEST_POSTED_DATE
                   FROM EDW_CURR.TAX_REGISTRATIONS_VALL PAYE
                  WHERE PAYE.DATE_CEASED = . AND
                        PAYE.TREG_STATUS = 'A' AND
                        PAYE.TAX_TYPE = 'PAY'
                  UNION
                 SELECT .         AS PAYE_REGISTERED_IRD,
                        B.IRD_NUMBER AS GST_RETURN_FILED_IRD,
                        MAX(A.IN_ACCOUNT) AS LATEST_POSTED_DATE /*BROUGHT THROUGH IN CASE WE NEED IT LATER*/
                   FROM TDW_CURR.TBL_RETURN_VALL   A
                   JOIN TDW_CURR.TBLNZ_RTNGST_VALL B ON A.DOC_KEY = B.DOC_KEY
                  WHERE A.DOC_TYPE = 'NZ.RTNGST' AND
                        A.CURRENT_REC_FLAG = 'Y' AND
                        B.CURRENT_REC_FLAG = 'Y' AND
                        A.IN_ACCOUNT > "&eff_date."D - 180 AND
                        (B.TOTAL_SALES > 0 OR B.P1_TOTAL_EXPENSES > 0 OR B.P2_TOTAL_EXPENSES > 0)
               GROUP BY B.IRD_NUMBER);
QUIT;
RUN;

PROC SORT DATA=ACTIVE_TRADING (WHERE=(IRD_NUMBER NE .)) 
          OUT=EXCLTEMP.ACTIVE_TRADING NODUPKEY; 
BY IRD_NUMBER; RUN;

