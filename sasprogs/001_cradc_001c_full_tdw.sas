/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 001_cradc_001c_full_tdw.sas

Overview:     Full extract of TDW data for CRADC
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      


%GetStarted;
/************************************************************************************************************************/
/*Table Prep
/*This step brings in the base data from the TDW tables.  Generally, only the current state data is extracted
/* (CURRENT_REC_FLAG = 'Y')
/************************************************************************************************************************/
DATA TDW_CURR.TBL_PERIODBILLITEM_R
    TDW_CURR.TBL_PERIODBILLITEM;
SET TDW.TBL_PERIODBILLITEM_VALL;
IF CURRENT_REC_FLAG = 'Y' AND STAGE EQ 'CRTCOL'                                                      THEN OUTPUT TDW_CURR.TBL_PERIODBILLITEM;
IF (STAGE EQ 'CRTCOL' AND PRIOR_STAGE NE 'CRTCOL') OR (STAGE NE 'CRTCOL' AND PRIOR_STAGE = 'CRTCOL') THEN OUTPUT TDW_CURR.TBL_PERIODBILLITEM_R;
RUN;
/************************************************************************************************************************/
DATA TDW_CURR.TBL_PERIOD_CRADC_DEBT    (KEEP=ACCOUNT_KEY FILING_PERIOD TAX INTEREST_BALANCE PENALTY_BALANCE BALANCE)
     TDW_CURR.TBL_PERIOD_CRADC_RETURN  (KEEP=ACCOUNT_KEY FILING_PERIOD)
	 TDW_CURR.TBL_PERIOD_CREDIT_LIST   (KEEP=IRD_NUMBER VER CURRENT_REC_FLAG FILING FILING_PERIOD BALANCE);
 SET TDW.TBL_PERIOD_VALL (WHERE=(CURRENT_REC_FLAG = 'Y' AND VER=0));
/*********************************************************************************************************************************/
/*  The data from this table is used in three places;
/*    - 'CRADC_DEBT' stage
/*    - 'CRDAC_RETURN' stage
/*    - 'Exclusion 026 - Credit List' stage
/*  They all have specific requirements.  So, rather than bringing in the entire table, just keeping the parts needed for each bit.
/*********************************************************************************************************************************/
IF BALANCE > 0                                                            THEN OUTPUT TDW_CURR.TBL_PERIOD_CRADC_DEBT;
IF ACTIVE = 1                                                             THEN OUTPUT TDW_CURR.TBL_PERIOD_CRADC_RETURN;
IF DATEPART(FILING_PERIOD) < INTNX('DAY',"&eff_date."D,-1,'END') AND BALANCE <0 THEN OUTPUT TDW_CURR.TBL_PERIOD_CREDIT_LIST;
/*********************************************************************************************************************************/
RUN;
/*********************************************************************************************************************************/
DATA tdw_curr.TBL_RETURN;               SET TDW.TBL_RETURN_VALL;                WHERE CURRENT_REC_FLAG = 'Y'; RUN;
/*********************************************************************************************************************************/
DATA tdw_curr.TBL_ACCOUNT;              SET TDW.TBL_ACCOUNT_VALL;               WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA tdw_curr.TBL_NZACCOUNTSTD;         SET TDW.TBL_NZACCOUNTSTD_VALL;          WHERE CURRENT_REC_FLAG = 'Y'; RUN;


DATA tdw_curr.TBL_NZ_ACCGSTINFO;        SET TDW.TBL_NZ_ACCGSTINFO_VALL;         WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA tdw_curr.TBL_CUSTOMER;             SET TDW.TBL_CUSTOMER_VALL;              WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA tdw_curr.TBL_CUSTOMERINFO;         SET TDW.TBL_CUSTOMERINFO_VALL;          WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA tdw_curr.TBL_INDICATOR;            SET TDW.TBL_INDICATOR_VALL;             WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA tdw_curr.TBL_COLLECT;              SET TDW.TBL_COLLECT_VALL;               WHERE CURRENT_REC_FLAG = 'Y'; RUN;
/************************************************************************************************************************/
DATA TDW_CURR.TBL_LEAD;                 SET TDW.TBL_LEAD_VALL;                  WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA TDW_CURR.TBL_LEDCCACTIONS;         SET TDW.TBL_LEDCCACTIONS_VALL;          WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA TDW_CURR.TBL_NZ_CAMPAIGN;          SET TDW.TBL_NZ_CAMPAIGN_VALL;           WHERE CURRENT_REC_FLAG = 'Y'; RUN;

DATA tdw_curr.TBL_COLLECTPERIOD;        SET TDW.TBL_COLLECTPERIOD_VALL;         WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA tdw_curr.TBL_COLLECTPAYMENTPLAN;   SET TDW.TBL_COLLECTPAYMENTPLAN_VALL;    WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA tdw_curr.TBL_NZ_INSTALMENTAGMTDEF; SET TDW.TBL_NZ_INSTALMENTAGMTDEF_VALL;  WHERE CURRENT_REC_FLAG = 'Y'; RUN;
DATA TDW_CURR.TBLNZ_RTNGST;             SET TDW.TBLNZ_RTNGST_VALL;              WHERE CURRENT_REC_FLAG = 'Y' 
                                                                  AND DATEPART(FILING_PERIOD) > '31MAR2010'D; RUN;
DATA tdw_curr.TBL_ACCOUNTINFO;          SET TDW.TBL_ACCOUNTINFO_VALL;           WHERE CURRENT_REC_FLAG = 'Y'; RUN;

/*DATA TDW_CURR.TBL_NZ_CASSECURTYINCIDENT;SET TDW.TBL_NZ_CASSECURTYINCIDENT_VALL; WHERE IRD_NUMBER NE . AND CURRENT_REC_FLAG = 'Y' AND EFFECTIVE_TO EQ .; RUN;*/
DATA TDW_CURR.TBL_LINK;                 SET TDW.TBL_LINK_VALL;                  WHERE CURRENT_REC_FLAG = 'Y' AND EFFECTIVE_TO EQ .;                     RUN;

DATA TDW_CURR.TBL_ALL_CASES;            SET TDW.TBL_ALL_CASES_VALL;             WHERE CURRENT_REC_FLAG = 'Y'; RUN;


/*PROC SORT DATA=TDW_CURR.TBL_NZ_CASSECURTYINCIDENT;    BY IRD_NUMBER CUSTOMER_KEY; RUN;*/
PROC SORT DATA=TDW_CURR.TBL_INDICATOR;                BY IRD_NUMBER CUSTOMER_KEY; RUN; 

/************************************************************************************************************************/
/*  Clear the connection to the TDW schema in EDW.
/************************************************************************************************************************/



%ErrCheck;