/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 141_excl_z041_customer_details.sas

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
/*CG 01MAY19 CUSTOMER DETAILS*/
/*Updated Customer Segment Code for R3*/
/*Now need to bring through Entity Type, Entity Class and Age Information*/
/*Need to review Entity logic with the multiple columns with R3 Prod Data*/
/*********************************************************************************************************************************/
/*Variables needed in one of the 4 main tables*/
/*CustomerSegment, EntityType, EntityClass, AgeEntity*/
/*********************************************************************************************************************************/
/*8Mins 9Secs*/
/*********************************************************************************************************************************/

DATA ExclTemp.CUSTOMERDETAILS;
MERGE   TDW_CURR.TBL_CUSTOMER_VALL       (IN=A
                                   KEEP=IRD_NUMBER CUSTOMER_KEY DOC_KEY CURRENT_REC_FLAG CUSTOMER_TYPE COMMENCE CEASE
                                  WHERE=(CURRENT_REC_FLAG = 'Y'))
	    TDW_CURR.TBL_NZ_CUSTOMERSTD_VALL (IN=B 
                                   KEEP=CUSTOMER_SEGMENT CUSTOMER_SUB_TYPE DOC_KEY CURRENT_REC_FLAG CUSTOMER_SUB_TYPE CUSTOMER_CLASS CUSTOMER_SUBTYPE_CLASS
                                  WHERE=(CURRENT_REC_FLAG = 'Y'))
		TDW_CURR.TBL_CUSTOMERSTD_VALL    (IN=C 
                                   KEEP=CUSTOMER_DOC_KEY DATE_OF_BIRTH DATE_OF_DEATH CURRENT_REC_FLAG 
                                 RENAME=(CUSTOMER_DOC_KEY=DOC_KEY)
                                  WHERE=(CURRENT_REC_FLAG = 'Y')) ;
BY DOC_KEY;

IF A;
LENGTH CUSTOMERSEGMENT $20;
/*Decode*/
     IF CUSTOMER_SEGMENT = 'FAM' THEN CustomerSegment = 'Families';
ELSE IF CUSTOMER_SEGMENT = 'IND' THEN CustomerSegment = 'Individuals';
ELSE IF CUSTOMER_SEGMENT = 'MIC' THEN CustomerSegment = 'Micro';
ELSE IF CUSTOMER_SEGMENT = 'SME' THEN CustomerSegment = 'SME';
ELSE IF CUSTOMER_SEGMENT = 'SIG' THEN CustomerSegment = 'Significant';
ELSE                                  CustomerSegment = 'NoSegment';

/***********************************************************************************/
/*Every Customer has a Commence Date and mainly only Individuals have Date of Birth*/
/*Date Of Birth is given priority to for the Individuals*/
/*Commence had approx 3K customers in NZS testing data that were different than DOB*/
/***********************************************************************************/
FORMAT START DATETIME20.;
FORMAT END DATETIME20.;
FORMAT START_DATE DATE9.;
FORMAT END_DATE DATE9.;
/***********************************************************************************/
IF CUSTOMER_TYPE = 'IND' AND DATE_OF_BIRTH NE '' THEN START = DATE_OF_BIRTH;
ELSE IF CUSTOMER_TYPE = 'IND'                    THEN START = COMMENCE;
ELSE IF COMMENCE = '' AND DATE_OF_BIRTH NE ''    THEN START = DATE_OF_BIRTH;
ELSE                                                  START = COMMENCE;
/***********************************************************************************/
     IF CUSTOMER_TYPE = 'IND' AND DATE_OF_DEATH NE '' THEN END = DATE_OF_DEATH;
ELSE IF CUSTOMER_TYPE = 'IND'                         THEN END = CEASE;
ELSE IF CEASE = '' AND DATE_OF_DEATH NE ''            THEN END = DATE_OF_DEATH;
ELSE                                                       END = CEASE;
/***********************************************************************************/
START_DATE = DATEPART(START);
END_DATE   = DATEPART(END);
/***********************************************************************************/
IF END_DATE NE '' THEN AgeEntity = INTCK('year',START_DATE,END_DATE);
ELSE                   AgeEntity = INTCK('year',START_DATE,TODAY());
/***********************************************************************************/
/*Customer Class and Customer Subtype Class are populated depending on CustomerType*/
/*Customer Class = Individuals*/
/*Customer Subtype Class = Others*/
/*Few minor exceptions for 2 customers in NZS testing data*/
/***********************************************************************************/
EntityType = CUSTOMER_SUB_TYPE;
     IF CUSTOMER_TYPE = 'IND' AND CUSTOMER_CLASS NE ''       THEN EntityClass = CUSTOMER_CLASS;
ELSE IF CUSTOMER_TYPE = 'IND'                                THEN EntityClass = CUSTOMER_SUBTYPE_CLASS;
ELSE IF CUSTOMER_SUBTYPE_CLASS = '' AND CUSTOMER_CLASS NE '' THEN EntityClass = CUSTOMER_CLASS;
ELSE                                                              EntityClass = CUSTOMER_SUBTYPE_CLASS;
RUN;
/*********************************************************************************************************************************/
PROC SORT DATA=ExclTemp.CUSTOMERDETAILS; BY IRD_NUMBER; RUN;
/*********************************************************************************************************************************/


