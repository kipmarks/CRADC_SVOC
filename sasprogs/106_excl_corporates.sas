/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 106_excl_corporates.sas

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
/* EXTRACTING LARGE ENTERPRISE (LE) INDICATOR RECORDS
/*********************************************************************************************************************************/
PROC SORT DATA=TDW_CURR.TBL_LINK      (WHERE=(LINK_TYPE IN('SUBSID','SESBPR')))        OUT=TBL_LINK;    BY FROM_CUSTOMER_KEY; RUN;
PROC SORT DATA=TDW_CURR.TBL_INDICATOR (WHERE=(INDICATOR_FIELD IN ('LRGENT','SIGENT'))) OUT=TBL_INDICATOR;    BY CUSTOMER_KEY; RUN;
PROC SORT DATA=TDW_CURR.TBL_CUSTOMERINFO (keep = current_rec_flag effective_to cease_date customer_key) OUT=TBL_CUSTOMERINFO; BY CUSTOMER_KEY; RUN;
/*********************************************************************************************************************************/
DATA WORK.CORPORATES_INDICATOR;
	MERGE TBL_INDICATOR (WHERE =(INDICATOR_FIELD = ('LRGENT') 
										AND VER =0 
										AND CURRENT_REC_FLAG ='Y' 
										AND MISSING (EFFECTIVE_TO)
										AND ACTIVE =1 
										AND ((MISSING(CEASE)  /*CURRENT INDICATORS*/										
										     AND (NOT (MISSING (COMMENCE)) /*NON NULL COMMENCE DATE; NULL COMMENCE DATE INDICATES AN INVALIDATED INDICATOR UNLESS....*/
											     OR (MISSING(COMMENCE) AND UPPER(WHO) <>'BATCH' AND WHO >='A')/*NOT TOUCHED BY AN USER OR BATCH PROCESS FOR E.G. ADDED BY CONVERSION -CNVR1*/
											     )
											 )
										    OR DATEPART(CEASE) > TODAY()  /*OR INDICATORS ENDING AT A FUTURE DATE*/										    
									        )
										)
								 IN =A)
/*MERGE TO BELOW TABLE IS TO ENSURE ONLY ACTIVE CUSTOMERS ARE FLAGGED AS CORPORATE ENTITIES AS RELIABILITY OF THIS INDICATOR FOR CEASED CUSTOMERS HASNT BEEN INVESTIGATED - 4636 CEASED RECORDS WITH LRGENT INDICATOR @11APR19*/
/*BUSINESS DECISION TO BE SOUGHT */
			TBL_CUSTOMERINFO (KEEP = CURRENT_REC_FLAG EFFECTIVE_TO CEASE_DATE CUSTOMER_KEY
									   WHERE =(CURRENT_REC_FLAG ='Y' AND MISSING (EFFECTIVE_TO) AND MISSING (CEASE_DATE)) IN=B
									  )
	;
	BY CUSTOMER_KEY;
IF A AND B;
KEEP CUSTOMER_KEY IRD_NUMBER;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA =WORK.CORPORATES_INDICATOR NODUPKEY; BY CUSTOMER_KEY IRD_NUMBER; RUN;
/*********************************************************************************************************************************/
/* EXTRACTING SIGNIFICANT ENTERPRISE (SE) INDICATOR RECORDS
/*********************************************************************************************************************************/
DATA WORK.SE_INDICATOR;
	MERGE TBL_INDICATOR (WHERE =(INDICATOR_FIELD = ('SIGENT') 
										AND VER =0 
										AND CURRENT_REC_FLAG ='Y' 
										AND MISSING (EFFECTIVE_TO)
										AND ACTIVE =1 
										AND ((MISSING(CEASE)  /*CURRENT INDICATORS*/										
										     AND (NOT (MISSING (COMMENCE)) /*NON NULL COMMENCE DATE; NULL COMMENCE DATE INDICATES AN INVALIDATED INDICATOR UNLESS....*/
											     OR (MISSING(COMMENCE) AND UPPER(WHO) <>'BATCH' AND WHO >='A')))/*NOT TOUCHED BY AN USER OR BATCH PROCESS FOR E.G. ADDED BY CONVERSION -CNVR1*/
										    OR DATEPART(CEASE) > TODAY()  /*OR INDICATORS ENDING AT A FUTURE DATE*/))
								 IN =A)
/*MERGE TO BELOW TABLE IS TO ENSURE ONLY ACTIVE CUSTOMERS ARE FLAGGED AS SIGNIFICANT ENTITIES AS RELIABILITY OF THIS INDICATOR FOR CEASED CUSTOMERS HASNT BEEN INVESTIGATED - 4636 CEASED RECORDS WITH LRGENT INDICATOR @11APR19*/
/*BUSINESS DECISION TO BE SOUGHT */
			TBL_CUSTOMERINFO (KEEP = CURRENT_REC_FLAG EFFECTIVE_TO CEASE_DATE CUSTOMER_KEY
								  WHERE =(CURRENT_REC_FLAG ='Y' AND MISSING (EFFECTIVE_TO) AND MISSING (CEASE_DATE)) IN=B);
BY CUSTOMER_KEY;
IF A AND B;
KEEP CUSTOMER_KEY IRD_NUMBER;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA =WORK.SE_INDICATOR NODUPKEY; BY CUSTOMER_KEY IRD_NUMBER; RUN;
/*********************************************************************************************************************************/
/* Extracting Parent to Subsidiary link records
/*********************************************************************************************************************************/
PROC SORT DATA=TBL_LINK; BY TO_CUSTOMER_KEY; RUN;
data work.Subsidiary;
	merge tbl_link (where =(link_type ='SUBSID'
		and ver =0
		and current_rec_flag ='Y'
		and missing (effective_To)
		and active =1
		and (missing(cease) or datepart(cease) > today())
		)
		rename= (from_customer_key =customer_key from_ird_number =ird_number to_customer_key =sub_customer_key to_ird_number = sub_ird_number)
		in =a
		)
		/*Merge to below table is to ensure only active customers are flagged as Corporate entities as reliability of this link for ceased customers hasnt been investigated*/

	/*Business decision to be sought */
	TBL_CUSTOMERINFO (keep = current_rec_flag effective_to cease_date customer_key
	where =(current_rec_flag ='Y' and missing (effective_to) and missing (cease_Date)) rename =(customer_key =sub_customer_key) in=b)
	;
	by sub_customer_key;

	if a and b;
	keep customer_key ird_number link_type sub_customer_key sub_ird_number;
run;
/*********************************************************************************************************************************/
/* Extracting SE Subsidiary to Parent link records
/*********************************************************************************************************************************/
PROC SORT DATA=TBL_LINK; BY FROM_CUSTOMER_KEY; RUN;
/*********************************************************************************************************************************/
data work.SESubsidiary;
	merge tbl_link (where =(link_type ='SESBPR'
									and ver =0
									and current_rec_flag ='Y'
									and missing (effective_To)
									and active =1
									and (missing(cease) or datepart(cease) > today())
									)
							 rename= (to_customer_key =customer_key to_ird_number =ird_number from_customer_key =sub_customer_key from_ird_number = sub_ird_number)
							 in =a
							 )
/*Merge to below table is to ensure only active customers are flagged as Corporate entities as reliability of this link for ceased customers hasnt been investigated*/
/*Business decision to be sought */
			TBL_CUSTOMERINFO (keep = current_rec_flag effective_to cease_date customer_key
									   where =(current_rec_flag ='Y' and missing (effective_to) and missing (cease_Date)) rename =(customer_key =sub_customer_key) in=b)
	;
	by sub_customer_key;
if a and b;
keep customer_key ird_number link_type sub_customer_key sub_ird_number;
run;
/*********************************************************************************************************************************/
/* Combining Subsidiary and SE Subsidiary link records
/*********************************************************************************************************************************/
data work.ParentSubsidiary; set  work.Subsidiary work.SESubsidiary; run;
/*********************************************************************************************************************************/
/* Sorting for a merge to only keep Subsidiary link records that either have a parent or subsidiary with LE indicator record
/*********************************************************************************************************************************/
proc sort data=work.CORPORATES_INDICATOR; by customer_key ird_number; run;
proc sort data=work.ParentSubsidiary; by customer_key ird_number; run;
/*********************************************************************************************************************************/
DATA WORK.PARENTSUBSIDIARYCORPORATES1;
	MERGE WORK.CORPORATES_INDICATOR (IN =A)
		  WORK.PARENTSUBSIDIARY     (IN =B);
BY CUSTOMER_KEY IRD_NUMBER;
IF A AND B;
RUN;
/*********************************************************************************************************************************/
proc sort data=work.ParentSubsidiary; by sub_customer_key sub_ird_number; run;
/*********************************************************************************************************************************/
data work.ParentSubsidiaryCorporates2;
	merge work.CORPORATES_INDICATOR (in =A)
		  work.ParentSubsidiary (rename= ( customer_key =customer_key1 ird_number =ird_number1 sub_customer_key =customer_key sub_ird_number =ird_number) in =B)
	;
	by customer_key ird_number;
if a and b;
keep customer_key1 ird_number1 link_type customer_key ird_number;
rename customer_key =sub_customer_key ird_number =sub_ird_number customer_key1 =customer_key ird_number1 =ird_number;
run;
/*********************************************************************************************************************************/
/* Sorting for a merge to only keep Subsidiary link records that either have a parent or subsidiary with SE indicator record
/*********************************************************************************************************************************/
proc sort data=work.SE_Indicator; by customer_key ird_number; run;
proc sort data=work.ParentSubsidiary; by customer_key ird_number; run;
/*********************************************************************************************************************************/
data work.ParentSubsidiarySE1;
	merge work.SE_Indicator     (in =A)
		  work.ParentSubsidiary (in =B);
	by customer_key ird_number;
if a and b;
run;
/*********************************************************************************************************************************/
proc sort data=work.ParentSubsidiary; by sub_customer_key sub_ird_number; run;
/*********************************************************************************************************************************/
data work.ParentSubsidiarySE2;
	merge work.SE_Indicator (in =A)
		  work.ParentSubsidiary (rename= ( customer_key =customer_key1 ird_number =ird_number1 sub_customer_key =customer_key sub_ird_number =ird_number) in =B)
	;
	by customer_key ird_number;
if a and b;
keep customer_key1 ird_number1 link_type customer_key ird_number;
rename customer_key =sub_customer_key ird_number =sub_ird_number customer_key1 =customer_key ird_number1 =ird_number;
run;
/*********************************************************************************************************************************/
/*Combine 1.LE indicator dataset 2.Subsidiary entities where Parent has LE indicator 3.Parent entities where Subsidiary has 
/*  LE indicator
/*********************************************************************************************************************************/
data work.CombineCorporates;
	set   work.CORPORATES_INDICATOR
		  work.Parentsubsidiarycorporates1 (keep =sub_customer_key sub_ird_number 
											 rename= (sub_customer_key = customer_key sub_ird_number = ird_number)
										     )
	      work.Parentsubsidiarycorporates2 (keep =customer_key ird_number)		  
	;
run;
/*********************************************************************************************************************************/
/*Remove dups and sort
/*********************************************************************************************************************************/
proc sort data =work.CombineCorporates nodupkey; by customer_key ird_number; run;
/*********************************************************************************************************************************/
/*Combine 1.SE indicator dataset 2.Subsidiary entities where Parent has SE indicator 3.Parent entities where Subsidiary 
/*  has SE indicator
/*********************************************************************************************************************************/
data work.CombineSE;
	set   work.SE_Indicator
		  work.ParentsubsidiarySE1 (keep =sub_customer_key sub_ird_number 
									 rename= (sub_customer_key = customer_key sub_ird_number = ird_number)
								    )
	      work.ParentsubsidiarySE2 (keep =customer_key ird_number)		  
	;
run;
/*********************************************************************************************************************************/
/*Remove dups and sort
/*********************************************************************************************************************************/
proc sort data =work.CombineSE nodupkey; by customer_key ird_number; run;
/*********************************************************************************************************************************/
/*Merge to eliminate any ceased entities and create LE or SE flag
/*********************************************************************************************************************************/
data ExclTemp.CorporatesAndSE;
	merge CombineCorporates (in=A)
	 	  CombineSE         (in=B)
/*Merge to below table is to ensure only active customers are flagged as Corporate entities as reliability of this indicator for ceased customers hasnt been investigated*/
/*Business decision to be sought */
		  TBL_CUSTOMERINFO (keep = current_rec_flag effective_to cease_date customer_key
		  				   where =(current_rec_flag ='Y' and missing (effective_to) and missing (cease_Date)) 
						       in=C);
	by customer_key;
if (a or b) and c;
drop current_rec_flag effective_to cease_Date;
Corporates =''; if a then Corporates ='Y'; else Corporates ='N';
SE =''; if b then SE ='Y'; else SE='N';
run;
/*********************************************************************************************************************************/
proc sort data=ExclTemp.CorporatesandSE noduprecs; by ird_number customer_key; run;
PROC DATASETS LIB=WORK NOLIST; 
DELETE TBL_LINK 
       TBL_INDICATOR 
       TBL_CUSTOMERINFO 
       CORPORATES_INDICATOR 
       SE_INDICATOR 
       SESUBSIDIARY 
       PARENTSUBSIDIARY 
       PARENTSUBSIDIARYCORPORATES1 
       PARENTSUBSIDIARYCORPORATES2 
       PARENTSUBSIDIARYSE1 
       PARENTSUBSIDIARYSE2 
       COMBINECORPORATES 
       COMBINESE
	   SUBSIDIARY;
RUN;
/*********************************************************************************************************************************/
