/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 001_cradc_002a_test_setup.sas

Overview:     Sets things up for testing CRADC in heritage DEV environment
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

July2019  	KM  Original
                                   
***********************************************************************/
%macro dragsubset(inds=,opds=,byvars=);
	proc sql;
		create table &opds. as
		select *
		from &inds.
		where ird_number in (select ird_number from cradcwrk.client_list);
		quit;
	run;
	%if &byvars. ne %then %do;
	proc sort data=&opds.;
		by &byvars.;
	run;
	%end;
%mend;

/******************************************************************************************/
/* CRADC testing */
/* Create some data for testing CRADC and refactoring */
/* First clean out the working areas */

%put CRADC test starts: %SYSFUNC(TIME(),time8.0);

proc datasets library=tdw_curr kill force;
run;
proc datasets library=edw_curr kill force;
run;
proc datasets library=did_tmp kill force;
run;
proc datasets library=cradcwrk kill force;
run;
proc datasets library=cradc kill force;
run;



/* Set up customers to test against */
proc sql;
	create table cradcwrk.client_list as
	select distinct ird_number
	from dansdata.kyc_tac_customers
	UNION
	select distinct agent_ird_number as ird_number
	from dansdata.kyc_tac_customers;
	quit;
run;
proc sort nodupkey data=cradcwrk.client_list(where=(ird_number>0));
	by ird_number;
run;

/************************************************************************************************************************/
/* Save some data for the compare at the end */
%dragsubset(inds=cradcx.cradc_svoc, opds=cradc.cradc_svoc_subset,byvars=);
