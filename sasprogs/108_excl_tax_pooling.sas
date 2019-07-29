/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 108_excl_tax_pooling.sas

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
/*  TAX POOLING 2019
/*  NOTES AND QUESTIONS CG 22MAR19
/*	UPDATED POST-R3 Go-Live CG 06MAY19
/*********************************************************************************************************************************/
/*  1. Based on the table structure supplied by Greg McPheat tbl_nz_tpaschedule_vall is a standalone table
/*  The other 3 TPA tables are related to the various payment, account and transaction tables
/*  These 3 other tables are focused around the actual TP payments, deposits etc NOT listing the customers
/*********************************************************************************************************************************/
/*  2. Currently unclear what data has been provided as most of the customers in tpaschedule
/*  Have not previously Tax Pooled - Therefore presuming this is NZS data
/*  Difficult to assess accuracy of data as cannot compare against previous years
/*  The same customers are have different TPA Keys (implying they are using multiple TPA intermediaries)
/*  This is possibly the tester in NZS using the same list customers over again
/*********************************************************************************************************************************/
/*  3. TPA Key - TPA Key - not entirely clear how it works - appears to relate back to the submitted Tax Pooling Schedule
/*********************************************************************************************************************************/
/*	4. TPA Tables do not appear to have all tax pooling customers as at 06May19
/*	Unclear where this TPA data comes from in START
/*	Most likely comes from MyIR then comes through web profiles in START
/*	Only 188 customers are in TPA Schedule and will follow up if this data is populating correctly
/*********************************************************************************************************************************/
/*	5. Indicator table contains a Tax Pooling indicator
/*	This contains approx 50K customers which is in line with the Tax Pooling numbers from previous years
/*	This includes the 188 from TPA Schefule
/*********************************************************************************************************************************/
/*	6. After discussion with Aaron and Tax Pooling SME NAMEEHRE
/*	The indicator gets udpated through some separate gateway process which covers everyone listed for taxpooling
/*	The TPA tables only contain customers who have transactional information and get updated from a separate process
/*	INTERIM SOLUTION
/*	Tax Pooling exclusion will be based on the Indicator table as it's currently more accurate
/*	Once the TPA tables populate fully or we better understand them they will just be a Y/N indicator in the table
/*********************************************************************************************************************************/

DATA WORK.TAXPOOL_SCHEDULE
(DROP=IRD_NUMBER RENAME=(IRD_NUMBER_TP = IRD_NUMBER));
MERGE 	TDW_CURR.TBL_NZ_TPASCHEDULE    (IN=A DROP=WHO EFFECTIVE_FROM EFFECTIVE_FROM WHERE=(CURRENT_REC_FLAG='Y'))
		TDW_CURR.TBL_NZ_TPATRANSFERLOG (IN=B KEEP=CUSTOMER_KEY TPA_KEY FILING_PERIOD TRANSFER CURRENT_REC_FLAG WHERE=(CURRENT_REC_FLAG='Y'));
BY TPA_KEY CUSTOMER_KEY;
IF A;
FORMAT IRD_NUMBER_TP BEST10.;
IRD_NUMBER_TP = IRD_NUMBER;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=WORK.TAXPOOL_SCHEDULE; BY CUSTOMER_KEY IRD_NUMBER; RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=TDW_CURR.TBL_INDICATOR OUT=WORK.TAXPOOL_INDICATOR;
BY CUSTOMER_KEY IRD_NUMBER; 
WHERE INDICATOR_FIELD = 'TAXPOL' AND CURRENT_REC_FLAG = 'Y' AND ACTIVE = 1 AND ((CEASE > TODAY()) OR (CEASE IS NULL));
RUN;
/*********************************************************************************************************************************/
DATA WORK.CMP_TAX_POOLING_EDS;
MERGE 	WORK.TAXPOOL_INDICATOR	(IN=A)
		WORK.TAXPOOL_SCHEDULE	(IN=B KEEP=CUSTOMER_KEY IRD_NUMBER);
BY CUSTOMER_KEY IRD_NUMBER;
IF A;
IF B THEN TAXPOOLINGSCHEDULE = 'Y'; ELSE TAXPOOLINGSCHEDULE = 'N';
RUN;

/*********************************************************************************************************************************/
PROC SORT DATA=WORK.CMP_TAX_POOLING_EDS OUT=EXCLTEMP.CMP_TAX_POOLING_EDS NODUP; BY IRD_NUMBER CUSTOMER_KEY; RUN;
PROC SORT DATA=EXCLTEMP.CMP_TAX_POOLING_EDS (KEEP=IRD_NUMBER) OUT=EXCLWork.CMP_TAX_POOLING_EDS_UNIQUE NODUPKEY;  BY IRD_NUMBER; RUN;
/*********************************************************************************************************************************/
PROC DATASETS LIB=WORK NOLIST; DELETE CMP_TAX_POOLING_EDS TAXPOOL_INDICATOR TAXPOOL_SCHEDULE; RUN;
/*********************************************************************************************************************************/
