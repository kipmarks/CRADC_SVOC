/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 001_cradc_002c_test_tdw.sas

Overview:     Test extract of TDW data for CRADC testing
              
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
            	 
                                      
***********************************************************************/

/********************************************************************/
/* For 002_cradc_specific_prep */
%dragsubset(inds=tdw_curx.tbl_periodbillitem,opds=tdw_curr.tbl_periodbillitem,byvars=);
%dragsubset(inds=tdw_curx.tbl_indicator, opds=tdw_curr.tbl_indicator,byvars=);
%dragsubset(inds=tdw_curx.tbl_customerinfo, opds=tdw_curr.tbl_customerinfo,byvars=);

/* For 003_cradc_debt_stage */
%dragsubset(inds=tdw_curx.tbl_return, opds=tdw_curr.tbl_return,byvars=);
%dragsubset(inds=tdw_curx.tbl_account, opds=tdw_curr.tbl_account,byvars=);
%dragsubset(inds=tdw_curx.tbl_nzaccountstd, opds=tdw_curr.tbl_nzaccountstd,byvars=);
/* And these two are linked by account_key - ird numbers are not present */
proc sql;
	create table tdw_curr.tbl_period_cradc_debt as
	select * from tdw_curx.tbl_period_cradc_debt
	where account_key in (select distinct account_key from tdw_curr.tbl_account);
	quit;
run;
proc sql;
	create table tdw_curr.tbl_period_cradc_return as
	select * from tdw_curx.tbl_period_cradc_return
	where account_key in (select distinct account_key from tdw_curr.tbl_account);
	quit;
run;

/* For 007_cradc_case_officers */
%dragsubset(inds=tdw_curx.tbl_collect, opds=tdw_curr.tbl_collect,byvars=);

/* For 009_cradc_days_in_debt */
/* Only the Lord knows why we need 2 different versions of this table. */
%dragsubset(inds=tdw_xxxx.tbl_periodbillitem,opds=tdw_curr.tbl_periodbillitem_r,byvars=);

/********************************************************************/
/********************************************************************/
/***** DONE UP TO HERE SO FAR ***************************************/
/********************************************************************/
/********************************************************************/




/*%dragsubset(inds=tdw_curx.tbl_period_credit_list, opds=tdw_curr.tbl_period_credit_list,byvars=);*/
/*%dragsubset(inds=tdw_curx.days_in_debt, opds=tdw_curr.days_in_debt,byvars=);*/
/*%dragsubset(inds=tdw_curx.special_customers, opds=tdw_curr.special_customers,byvars=);*/
/*%dragsubset(inds=tdw_curx.tbl_accountinfo, opds=tdw_curr.tbl_accountinfo,byvars=);*/
/*%dragsubset(inds=tdw_curx.tbl_all_cases, opds=tdw_curr.tbl_all_cases,byvars=);*/
/**/
/*%dragsubset(inds=tdw_curx.tbl_collectpaymentplan, opds=tdw_curr.tbl_collectpaymentplan,byvars=);*/
/*%dragsubset(inds=tdw_curx.tbl_collectperiod, opds=tdw_curr.tbl_collectperiod,byvars=);*/
/*%dragsubset(inds=tdw_curx.tbl_customer, opds=tdw_curr.tbl_customer,byvars=);*/
/*%dragsubset(inds=tdw_curx.tbl_lead, opds=tdw_curr.tbl_lead,byvars=);*/
/*%dragsubset(inds=tdw_curx.tbl_ledccactions, opds=tdw_curr.tbl_ledccactions,byvars=);*/

/* Tbl_link is different */
/*proc sql;*/
/*		create table tdw_curr.tbl_link as*/
/*		select **/
/*		from tdw_curx.tbl_link*/
/*		where to_ird_number   in (select ird_number from cradcwrk.client_list)*/
/*		   OR from_ird_number in (select ird_number from cradcwrk.client_list);*/
/*		quit;*/
/*run;*/
/*%dragsubset(inds=tdw_curx.tbl_nz_accgstinfo, opds=tdw_curr.tbl_nz_accgstinfo,byvars=);*/
/*%dragsubset(inds=tdw_curx.tbl_nz_instalmentagmtdef, opds=tdw_curr.tbl_nz_instalmentagmtdef,byvars=);*/
/*%dragsubset(inds=tdw_curx.tbl_return, opds=tdw_curr.tbl_return,byvars=);*/
/*%dragsubset(inds=tdw_curx.tblnz_rtngst, opds=tdw_curr.tblnz_rtngst,byvars=);*/

/* tbl_nz_campain is different - linked by collect_key */
/*proc sql;*/
/*	create table tdw_curr.tbl_nz_campaign as*/
/*	select * from tdw_curx.tbl_nz_campaign*/
/*	where collect_key in (select distinct collect_key from tdw_curr.tbl_collect);*/
/*	quit;*/
/*run;*/


/************************************************************************************************************************/


