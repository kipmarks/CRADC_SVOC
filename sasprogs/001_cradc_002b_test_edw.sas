/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 001_cradc_002b_test_edw.sas

Overview:     Extract test sample of EDW data for CRADC testing
              
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

/* For 003_cradc_debt_stage */
%dragsubset(inds=edw_curx.current_elements,opds=edw_curr.current_elements,byvars=);

/* For 005_cradc_return_stage */
%dragsubset(inds=edw_curx.policing_profiles,opds=edw_curr.policing_profiles,byvars=ird_number location_number return_period_date);

/* For 007_cradc_case_officers */
%dragsubset(inds=edw_curx.tax_csa,opds=edw_curr.tax_csa,byvars=ird_number location_number tax_type descending treg_date_start);
%dragsubset(inds=edw_curx.cases,opds=edw_curr.cases_vall,byvars=case_key);
%dragsubset(inds=edw_curx.case_actions,opds=edw_curr.case_actions_vall,byvars=);

/* For 008_cradc_special_customers */
%dragsubset(inds=edw_curx.special_clients,opds=edw_curr.special_clients,byvars=ird_number);

/* For 009_cradc_days_in_debt */
%dragsubset(inds=edw_curx.elements_all,opds=edw_curr.elements_all,byvars=case_key return_period_date);

/* For 010_cradc_case_actions */
%dragsubset(inds=edw_curx.case_actions_current,opds=edw_curr.case_actions_current,byvars=);





/***************************************************************************/

/* Cross_references is different */
/*proc sql;*/
/*		create table edw_curr.cross_references as*/
/*		select **/
/*		from edw_curx.cross_references*/
/*		where ird_number_to   in (select ird_number from cradcwrk.client_list)*/
/*		   OR ird_number_from in (select ird_number from cradcwrk.client_list);*/
/*		quit;*/
/*run;*/
/*%dragsubset(inds=edw_curx.cs_assessments,opds=edw_curr.cs_assessments,byvars=);*/
/*%dragsubset(inds=edw_curx.elements,opds=edw_curr.elements,byvars=case_key return_period_date);*/
/*%dragsubset(inds=edw_curx.policing_profiles,opds=edw_curr.policing_profiles,byvars=ird_number location_number return_period_date);*/

/* Proper testing requires the following.... */
/* but we have changed 07_case_officers.sas to use tables without _vall extension*/
/*%dragsubset(inds=edw_curx.cases_vall,opds=edw_curr.cases_vall,byvars=case_key);*/
/*%dragsubset(inds=edw_curx.case_actions_vall,opds=edw_curr.case_actions_vall,byvars=);*/
/*%dragsubset(inds=edw_curx.tax_csa_vall,opds=edw_curr.tax_csa_vall,byvars=ird_number location_number tax_type descending treg_date_start);*/


/************************************************************************************************************************/
/* EDW for Exclusions */
