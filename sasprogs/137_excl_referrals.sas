/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 137_excl_referrals.sas

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
DATA ExclTemp.CMP_REFERRALS;
MERGE
	TDW_CURR.TBL_TASKOPEN_VALL  (in=a WHERE=(VER=0 AND CURRENT_REC_FLAG='Y'  
     									AND TASK_TYPE IN 
              ('AUDREF', 'COLREF', 'INSREF', 'PROREF','AADREF','ICLREF','REFCMP')))
	TDW_CURR.TBL_TASKQUEUE_VALL (IN=B KEEP= QUEUE_KEY QUEUE_ID QUEUE_ORDER QUEUE_NAME OWNER 
                                   DESCRIPTION ACTIVE CURRENT_REC_FLAG	
	                        WHERE=(CURRENT_REC_FLAG='Y' AND ACTIVE=1 ));
BY QUEUE_KEY;
IF A AND B;

     IF TASK_TYPE = 'AUDREF'    THEN REFERRALTYPE = 'Audit Referral';
ELSE IF TASK_TYPE = 'COLREF' 	THEN REFERRALTYPE = 'Collection Referral';
ELSE IF TASK_TYPE = 'INSREF' 	THEN REFERRALTYPE = 'Insolvency Referral';
ELSE IF TASK_TYPE = 'PROREF' 	THEN REFERRALTYPE = 'Prosecution Referral';
ELSE IF TASK_TYPE = 'AADREF' 	THEN REFERRALTYPE = 'AAD Referral';
ELSE IF TASK_TYPE = 'ICLREF' 	THEN REFERRALTYPE = 'International Collection Referral';
ELSE IF TASK_TYPE = 'REFCMP' 	THEN REFERRALTYPE = 'Community Compliance Referral';
ELSE								 REFERRALTYPE = '???';			

RUN;

PROC SORT DATA=ExclTemp.CMP_REFERRALS; 
BY CUSTOMER_KEY CREATED; 
RUN;

DATA CMP_REFERRALS_UNIQUE (keep=customer_key REFERRALCREATEDON REFERRALTYPE);
 SET ExclTemp.CMP_REFERRALS;
FORMAT REFERRALCREATEDON DDMMYY10.;
REFERRALCREATEDON = DATEPART(CREATED);
IF REFERRALCREATEDON <= "&eff_date."D -90 THEN DELETE;
RUN;

DATA CMP_REFERRALS_UNIQUE;
 SET CMP_REFERRALS_UNIQUE;
BY CUSTOMER_KEY;
IF LAST.CUSTOMER_KEY THEN OUTPUT;
RUN;

PROC SORT DATA=TDW_CURR.TBL_CUSTOMER 
          OUT=TBL_CUSTOMER(KEEP=CUSTOMER_KEY IRD_NUMBER); 
BY CUSTOMER_KEY; 
RUN;


DATA ExclTemp.CMP_REFERRALS_UNIQUE;
MERGE TBL_CUSTOMER         (IN=A) 
      CMP_REFERRALS_UNIQUE (IN=B);
BY CUSTOMER_KEY;
IF B;
RUN;

PROC SORT DATA=ExclTemp.CMP_REFERRALS_UNIQUE NODUPKEY; 
BY IRD_NUMBER; 
RUN;
