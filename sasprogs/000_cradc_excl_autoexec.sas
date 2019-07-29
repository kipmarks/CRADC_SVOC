/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 000_cradc_excl_autoexec.sas

Overview:     Autoexec for CRADC/EXCL processing.
              
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

26Jul2019   KM  Richard H. moved the location of prod work data.
June2019  	KM  Migration to DIP. Created from original code-nodes 
            02_Macros.sas, 03_Libs.sas, 04_Clear_Temp_libs.sas
            Macros moved to sasautos/autocalls subdirectory, one macro per file.
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	                                 
***********************************************************************/
/* Set up for running on heritage.  */
%global dataroot;
%let dataroot=/data/shared/shared_iic_pff/CVP/cradc_testing/;

/* Temp libs - Clear ready for use. */
libname edw_curr "&dataroot.edw_curr/";
libname tdw_curr "&dataroot.tdw_curr/";
libname did_tmp  "&dataroot.did_tmp/";
libname cradcwrk "&dataroot.cradc_work/";

/* Output directory */
libname cradc    "&dataroot.cradc"   ;


%global exclroot;
%let exclroot=/data/shared/shared_iic_pff/CVP/excl_testing/;

libname csdr "&exclroot./debt_report/";
libname exclwork "&exclroot./excl_work/";
libname excltemp "&exclroot./excl_temp/";
libname camexcl "&exclroot./camexcl/";
libname b10debt "&exclroot./b10debt/";

/* These for creating test data */
/* Read-only libnames for creating test data */
libname csdrx     "/data/shared/iic/intel_delivery/collections/cs/Common/Common Data/Debt Report";
libname cradcx    "/data/shared/iic/intel_delivery/common/temp_data/cradc/"   ;
libname exclworx "/data/shared/iic/intel_delivery/common/excls_vars/work_tables/" ; /*  work storage while exclusion tables are being built  */
libname excltemx "/data/shared/iic/intel_delivery/common/excls_vars/base_tables/" ; /*  temp storage while exclusion tables are being built  */
libname camexclx  "/data/shared/iic/intel_delivery/common/excls_vars/"             ; /*  final destination for exclusion tables               */
libname b10debtx  "/data/shared/iic/intel_delivery/collections/b10/2017/sasdata";

/* This is the old and illegal location */
/*%let dataroox=/data/saswork1/iic/cradc_files/;   */
%let dataroox=/data/shared/iic/intel_delivery/common/temp_data/;   
libname cradcwrx "&dataroox.cradc_work/";
libname edw_curx "&dataroox.edw_curr/";
libname tdw_curx "&dataroox.tdw_curr/";
libname tdw_xxxx "&dataroox.tdw_raw/";
libname did_tmpx "&dataroox.did_tmp/";

/* For a small list of tax agents and their clients    */
libname dansdata '/data/shared/iic/intel_delivery/collections/b10/2017/7apr/sasdata';

/*********************************************************************************************************************************/
/*Set the connection to the DSS and TDW schema in EDW.  As well as DW   READBUFF set to maximum
/*********************************************************************************************************************************/
LIBNAME DSS ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP SCHEMA='DSS' READBUFF=32687;
LIBNAME TDW ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP SCHEMA='TDW' READBUFF=32687;
LIBNAME DSSMART ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP SCHEMA='DSSMART' READBUFF=32687 INSERTBUFF=32687 DBCOMMIT=32687;
LIBNAME SUMMARY ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP SCHEMA='SUMMARY' READBUFF=32687 INSERTBUFF=32687 DBCOMMIT=32687;
LIBNAME D67AWCH ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP SCHEMA='67AWCH' READBUFF=32687 INSERTBUFF=32687 DBCOMMIT=32687;


/********************************************************************/
/* As-at date. Hard-wire this for testing or get it from column effective_date 
/* in dataset CRADCX.CRADC_SVOC. +1 for next-day processing!  */
%global eff_date;
%let eff_date=24JUL2019;
/*proc sql;*/
/*select max(effective_date) as mxdt format date9. into :eff_date */
/*from cradcx.cradc_svoc;*/
/*quit;*/
/*run;*/
/*%put &eff_date.;*/
/********************************************************************/
