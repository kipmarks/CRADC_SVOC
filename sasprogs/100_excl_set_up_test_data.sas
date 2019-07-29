/* 103_excl_cmp_control */
PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1"  PATH=DWP);
CREATE TABLE EXCLTEMP.CMPS_CNTRL AS SELECT * FROM CONNECTION TO MYORACON (
SELECT DISTINCT B.IRD_NUMBER,
                C.COMM_BUSINESS_UNIT,
                C.COMM_DESC,
                C.BILATERAL,
                C.COMM_START_DATE,
                C.COMM_END_DATE
           FROM "67AWCH".CMP_MASTER_CTRL   B
     INNER JOIN "67AWCH".CMP_COMMUNICATION C ON B.COMMUNICATION_ID = C.COMMUNICATION_ID
           WHERE (SYSDATE - C.COMM_END_DATE < 180 AND C.BILATERAL NOT IN (1,3.1)) OR 
                 SYSDATE - C.COMM_END_DATE < 60);
DISCONNECT FROM MYORACON;
QUIT;

/* 104_excl_cmp_holding_tank */
PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1"  PATH=DWP);
CREATE TABLE ExclTemp.CMPS_HOLDING_TANK AS SELECT * FROM CONNECTION TO MYORACON (
    SELECT DISTINCT B.IRD_NUMBER,
                    B.REASON,
                    B.EXPIRY_DATE
               FROM "67AWCH".CMP_HOLDING_TANK B)
ORDER BY IRD_NUMBER, EXPIRY_DATE;
DISCONNECT FROM MYORACON;
QUIT;

/* 109_excl_recent_campaigns.sas */
PROC SQL;
CONNECT TO ORACLE AS MYORACON (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1"  PATH=DWP);
CREATE TABLE ExclTemp.PREV_CMPS AS SELECT * FROM CONNECTION TO MYORACON (
SELECT DISTINCT B.IRD_NUMBER,
                B.LOCATION_NUMBER,
                B.CASE_NUMBER,
                C.COMMUNICATION_ID AS COMM_ID,
                C.COMM_DESC,
                C.COMM_START_DATE,
                C.COMM_END_DATE,
                C.COMM_SHORT_DESC,
                CAST(C.BILATERAL AS NUMBER(*,2)) AS BILATERAL
           FROM "67AWCH".CMP_MASTER        B
     INNER JOIN "67AWCH".CMP_COMMUNICATION C ON B.COMMUNICATION_ID = C.COMMUNICATION_ID
          WHERE  SYSDATE - C.COMM_END_DATE < 90);
DISCONNECT FROM MYORACON;
QUIT;

/* 125_excl_cmp_strike_offs.sas */
/* NO ACCESS AT PRESENT */
/*PROC SQL;*/
/*CONNECT TO ORACLE AS MYORACON  (USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1"  PATH=DWP  READBUFF=32767);*/
/*CREATE TABLE EXCLTEMP.STRUCK_OFF_COMPANIES AS SELECT * FROM CONNECTION TO MYORACON(*/
/*SELECT IRD_NUMBER, NAME, ID_SERIAL_NUMBER FROM "17THHO".STRUCK_OFF_COMPANIES);*/
/*DISCONNECT FROM MYORACON;*/
/*QUIT;*/
/*PROC SORT DATA=EXCLTEMP.STRUCK_OFF_COMPANIES NODUPKEY; */
/*BY IRD_NUMBER NAME ID_SERIAL_NUMBER; */
/*RUN;*/


/* Test data needed for Exclusions */
/********************************************************************/
%macro dragsubset(inds=,opds=,byvars=,irdvar=ird_number);
	proc sql;
		create table &opds. as
		select *
		from &inds.
		where &irdvar. in (select ird_number from cradcwrk.client_list);
		quit;
	run;
	%if &byvars. ne %then %do;
	proc sort data=&opds.;
		by &byvars.;
	run;
	%end;
%mend;
%macro dragsubst2(inds=,opds=,byvars=,var1=,var2=);
	proc sql;
		create table &opds. as
		select *
		from &inds.
		where &var1. in (select &var2. as &var1. from exclwork.tdw_keys1);
		quit;
	run;
	%if &byvars. ne %then %do;
	proc sort data=&opds.;
		by &byvars.;
	run;
	%end;
%mend;
%macro dragsubst3(inds=,opds=,byvars=,irdvar=ird_number);
	proc sql;
		create table &opds. as
		select *
		from &inds.(where=(date_received >= "30Jun2018"D))
		where &irdvar. in (select ird_number from cradcwrk.client_list);
		quit;
	run;
	%if &byvars. ne %then %do;
	proc sort data=&opds.;
		by &byvars.;
	run;
	%end;
%mend;
%macro dragsubst4(inds=,opds=,byvars=,irdvar=ird_number);
	proc sql;
		create table &opds. as
		select *
		from &inds.(where=(return_period_date >= "01Jan2018"D))
		where &irdvar. in (select ird_number from cradcwrk.client_list);
		quit;
	run;
	%if &byvars. ne %then %do;
	proc sort data=&opds.;
		by &byvars.;
	run;
	%end;
%mend;

%dragsubset(inds=csdrx.cs_daily_debt_report_hist, opds=csdr.cs_daily_debt_report_hist,byvars=);

%dragsubset(inds=tdw.tbl_nz_cassecurtyincident_view, opds=tdw_curr.tbl_nz_cassecurtyincident,byvars=);
proc sort data=tdw_curr.tbl_nz_cassecurtyincident;
	by ird_number customer_key;
run;
%dragsubset(inds=camexclx.sid_history, opds=camexcl.sid_history,byvars=,irdvar=irdnumber);

proc sort data=tdw_curr.tbl_all_cases;
by ird_number;
run;


/* ird_number is char(9) in this TDW table */
%dragsubset(inds=tdw.TBL_NZ_TPASCHEDULE_VIEW, 
            opds=tdw_curr.TBL_NZ_TPASCHEDULE,
            byvars=tpa_key customer_key,irdvar=%STR(input(ird_number,F9.)));
/* No IRD number at all in this one, so use the other version of the macro */
%dragsubst2(inds=tdw.TBL_NZ_TPATRANSFERLOG_VIEW, 
            opds=tdw_curr.TBL_NZ_TPATRANSFERLOG,
            byvars=tpa_key customer_key,var1=customer_key,var2=customer_key);

/***** 113_excl_overseas_taxpayers */

%dragsubset(inds=dss.client_codes_view, opds=edw_curr.client_codes_vall,byvars=,irdvar=ird_number);
%dragsubset(inds=dss.customers_current_view, opds=edw_curr.customers_current_vall,byvars=,irdvar=ird_number);


%dragsubset(inds=tdw.tbl_customer_view, 
            opds=tdw_curr.tbl_customer_vall,
            byvars=DOC_KEY,irdvar=ird_number);

%dragsubset(inds=tdw.tbl_customerinfo_view, 
            opds=tdw_curr.tbl_customerinfo_vall,
            byvars=,irdvar=ird_number);


/* This one needs doc_key for gods sake */
*%dragsubset(inds=tdw.tbl_nz_customerstd_view, opds=tdw_curr.tbl_nz_customerstd_vall,byvars=,irdvar=ird_number);
data tdw_curr.tbl_nz_customerstd_vall;
	set tdw.tbl_nz_customerstd_view(KEEP=DOC_KEY CURRENT_REC_FLAG CURRENT_TAX_RESIDENCY CUSTOMER_:		
           WHERE= (CURRENT_REC_FLAG = 'Y' 
                  AND CURRENT_TAX_RESIDENCY NE 'NEZ' 
                  AND CURRENT_TAX_RESIDENCY NE ''));
run;
proc sort data=tdw_curr.tbl_nz_customerstd_vall;
	by doc_key;
run;

%dragsubset(inds=tdw.tbl_addressrecord_view, 
            opds=tdw_curr.tbl_addressrecord_vall,
                 byvars=,irdvar=ird_number);

/* 116_excl_death_notice.sas */
%dragsubset(inds=tdw.tbl_cstindinfo_view, 
            opds=tdw_curr.tbl_cstindinfo_vall,
            byvars=,irdvar=ird_number);

%dragsubst2(inds=tdw.tbl_crmlog_view, 
            opds=tdw_curr.tbl_crmlog_vall,
            byvars=,var1=customer_key,var2=customer_key);

%dragsubst3(inds=dss.correspondence_inbound_view, 
            opds=edw_curr.correspondence_inbound_vall,
            byvars=,irdvar=ird_number);

/* 117_dia_death_notices */
data camexcl.dia_death_notice;
	set camexclx.dia_death_notice;
run;

/* 121_excl_is_a_tax_agent.sas */
%dragsubset(inds=tdw.tbl_id_view, 
            opds=tdw_curr.tbl_id_vall,
            byvars=,irdvar=ird_number);

/* 122_excl_tax_agent_links.sas */
%dragsubset(inds=dss.current_tax_registrations_view, 
            opds=edw_curr.current_tax_registrations_vall,
            byvars=,irdvar=ird_number);
/* 124_excl_sls_cal_issues.sas */
%dragsubset(inds=dssmart.crown_sl_outstanding_blns_view, 
            opds=edw_curr.crown_sl_outstanding_blns_vall,
            byvars=,irdvar=ird_number);

/* 126_excl_credit_list.sas */
%dragsubst4(inds=dss.client_inc_indicators_view, 
            opds=edw_curr.client_inc_indicators_vall,
            byvars=,irdvar=ird_number);

/* 127_txt_opt_out.sas */

/* 128_excl_start_deductions */
%dragsubst2(inds=tdw.tbl_garnishtopbi_view, 
            opds=tdw_curr.tbl_garnishtopbi_vall,
            byvars=,var1=customer_key,var2=customer_key);
			
%dragsubst2(inds=tdw.tbl_garnish_view, 
            opds=tdw_curr.tbl_garnish_vall,
            byvars=,var1=customer_key,var2=customer_key);

%dragsubst2(inds=tdw.tbl_nz_garnishdetails_view, 
            opds=tdw_curr.tbl_nz_garnishdetails_vall,
            byvars=,var1=customer_key,var2=customer_key);

%dragsubst2(inds=tdw.tbl_nz_garnishattribut_view, 
            opds=tdw_curr.tbl_nz_garnishattribut_vall,
            byvars=,var1=customer_key,var2=customer_key);

/* 130_open_and_recent_audit_interventions.sas */
%dragsubst2(inds=tdw.tbl_auditgroupcustomer_view, 
            opds=tdw_curr.tbl_auditgroupcustomer_vall,
            byvars=,var1=customer_key,var2=customer_key);

%dragsubst2(inds=tdw.tbl_auditgroup_view, 
            opds=tdw_curr.tbl_auditgroup_vall,
            byvars=,var1=customer_key,var2=customer_key);


/* No customer key in this one */
data tdw_curr.TBL_NZ_AUDSELECTNATTRS_VALL;
	set tdw.TBL_NZ_AUDSELECTNATTRS_VIEW(where=(DATEPART(effective_from)>"01JAN2017"D));
run;

%dragsubst2(inds=tdw.TBL_AUDIT_VIEW, 
            opds=tdw_curr.TBL_AUDIT_VALL,
            byvars=,var1=customer_key,var2=customer_key);

%dragsubst2(inds=tdw.TBL_AUDITDETAIL_VIEW, 
            opds=tdw_curr.TBL_AUDITDETAIL_VALL,
            byvars=,var1=customer_key,var2=customer_key);


/* 130_z029_CAYD_income.sas */
proc sql;
		create table edw_curr.employee_paye_summaries_vall as
		select *
		from dss.employee_paye_summaries_view(where=(return_period_date >= "30Jun2016"D))
		where employee_ird_number in (select ird_number from cradcwrk.client_list);
		quit;
run;


/* 133_excl_open_corre.sas */
%dragsubst2(inds=tdw.TBL_TASKOPEN_VIEW, 
            opds=tdw_curr.TBL_TASKOPEN_VALL,
            byvars=queue_key,var1=customer_key,var2=customer_key);

/* 137_excl_referrals.sas */
data TDW_CURR.TBL_TASKQUEUE_VALL;
	set TDW.TBL_TASKQUEUE_VIEW(where=(current_rec_flag='Y' and DATEPART(effective_from)>"01JAN2016"D));
run;
proc sort data=TDW_CURR.TBL_TASKQUEUE_VALL;
by queue_key;
run;


/* 141_z027_028_contact_details_alternative.sas */
%dragsubst2(inds=tdw.TBL_CONTACT_VIEW, 
            opds=tdw_curr.TBL_CONTACT_VALL,
            byvars=,var1=customer_key,var2=customer_key);

data edw_curr.return_line_items_vall;
	set dss.return_line_items_view(keep= employee_ird_number employer_ird_number 
                                         return_type return_period_date
                                         where=(DATEPART(return_period_date) > "&eff_date."D - 180
                                                AND return_type in ('IR348')));
run;


/* 141_excl_z015_bic_codes.sas */
/* No access to 67AWCH.cmp_sic_codes_and_groups */

/* 141_excl_z017_age_of_nrb_start.sas */
%dragsubset(inds=summary.sl_obb_monthly_summary_view, 
            opds=edw_curr.sl_obb_monthly_summary_vall,
            byvars=,irdvar=ird_number);

/* 141_excl_z019_property_ownership.sas */
%dragsubset(inds=camexclx.cmp_property_ownership, 
            opds=camexcl.cmp_property_ownership,
            byvars=,irdvar=ird_number);

/* 141_excl_z020_sls_334_debt.sas */
%dragsubset(inds=dss.elements_view, 
            opds=edw_curr.elements_vall,
            byvars=,irdvar=ird_number);

/* 141_excl_026_current_fam_payment_indicator */
PROC SQL;
CREATE TABLE tdw_curr.TBL_NZ_FAMENTITLEMENT_VALL AS
SELECT *
FROM tdw.TBL_NZ_FAMENTITLEMENT_VIEW
WHERE account_key IN (SELECT DISTINCT account_key 
                      FROM TDW_CURR.TBL_ACCOUNT
					  WHERE current_rec_flag="Y"
					    AND customer_key in (SELECT DISTINCT customer_key FROM exclwork.tdw_keys1))
AND DATEPART(filing_period) > INTNX('MONTH',"&eff_date."D,-24,"BEGINNING");
QUIT;
RUN;

/* 141_excl_z029_age_of_last_heritage_action.sas */
%dragsubset(inds=dssmart.CUR_DEBT_CASES_OUTSTANDING_VW, 
            opds=edw_curr.CUR_DEBT_CASES_OUTSTANDING_VA,
            byvars=,irdvar=ird_number);

/* 141_excl_z031_last_contact_inbound.sas */

PROC SQL;
CREATE TABLE tdw_curr.TBL_TASKCLOSED_VALL AS
SELECT *
FROM tdw.TBL_TASKCLOSED_VIEW
WHERE customer_key in (SELECT DISTINCT customer_key FROM exclwork.tdw_keys1)
AND CURRENT_REC_FLAG="Y"
AND DATEPART(created) > INTNX('MONTH',"&eff_date."D,-24,"BEGINNING");
QUIT;
RUN;

/* 141_excl_z033_penalty_and_interest_ratio.sas  */

/* 141_excl_z034_active_trading.sas  */
%dragsubst2(inds=tdw.TBL_RETURN_VIEW, 
            opds=tdw_curr.TBL_RETURN_VALL,
            byvars=,var1=customer_key,var2=customer_key);

PROC SQL;
CREATE TABLE tdw_curr.TBL_ACCOUNT_VALL AS
SELECT *
FROM tdw.TBL_ACCOUNT_VIEW
WHERE customer_key in (SELECT DISTINCT customer_key FROM exclwork.tdw_keys1)
AND CURRENT_REC_FLAG="Y"
AND DATEPART(created) > INTNX('MONTH',"&eff_date."D,-24,"BEGINNING");
QUIT;
RUN;

%dragsubst2(inds=tdw.TBLNZ_RTNGST_VIEW, 
            opds=tdw_curr.TBLNZ_RTNGST_VALL,
            byvars=,var1=customer_key,var2=customer_key);

%dragsubset(inds=dss.tax_registrations_view, 
            opds=edw_curr.tax_registrations_vall,
            byvars=,irdvar=ird_number);

/* 141_excl_z041_customer_details */
%dragsubst2(inds=tdw.TBL_CUSTOMERSTD_VIEW, 
            opds=tdw_curr.TBL_CUSTOMERSTD_VALL,
            byvars=customer_doc_key,var1=customer_key,var2=customer_key);


/* 150_excl_geographic_locations.sas */




/* No access to tables in SXT4 */