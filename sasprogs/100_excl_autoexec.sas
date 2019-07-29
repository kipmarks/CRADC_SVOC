/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 100_excl_autoexec.sas

Overview:     Autoexec for exclusions processing.
              Must be run after CRADC processing.
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP. Created from original code-nodes
            000_AUTOCALL_CATALOGUE.sas, 000_Libs.sas, 000_Macros.sas
2015-2019  	Original EXCL development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/* Set up for running on heritage.  */
%global dataroot;
%let dataroot=/data/shared/shared_iic_pff/CVP/cradc_testing/;

/* Temp libs - Clear ready for use? */
libname edw_curr "&dataroot.edw_curr/";
libname edw_raw  "&dataroot.edw_raw/";
libname tdw_curr "&dataroot.tdw_curr/";
libname tdw_raw  "&dataroot.tdw_raw/";
libname did_tmp  "&dataroot.did_tmp/";
libname cradcwrk "&dataroot.cradc_work/";
/* Clean run */
/*proc datasets lib=edw_curr kill nodetails nolist; run;*/
/*proc datasets lib=edw_raw  kill nodetails nolist; run;*/
/*proc datasets lib=tdw_curr kill nodetails nolist; run;*/
/*proc datasets lib=tdw_raw  kill nodetails nolist; run;*/
/*proc datasets lib=did_tmp  kill nodetails nolist; run;*/

/* Other inputs? */
/* Output directory from CRADC and temp libs*/
libname cradc    "&dataroot.cradc"   ;

/********************************************************************/
/* As-at date */
/* For now get this from column effective_date in dataset CRADCX.CRADC_SVOC */
%global eff_date;
%let eff_date=24JUN2019;
/********************************************************************/


%global exclroot;
%let exclroot=/data/shared/shared_iic_pff/CVP/excl_testing/;

libname csdr "&exclroot./debt_report/";
libname exclwork "&exclroot./excl_work/";
libname excltemp "&exclroot./excl_temp/";
libname camexcl "&exclroot./camexcl/";
libname b10debt "&exclroot./b10debt/";



/* These for creating test data */
libname csdrx     "/data/shared/iic/intel_delivery/collections/cs/Common/Common Data/Debt Report";
libname cradcx    "/data/shared/iic/intel_delivery/common/temp_data/cradc/"   ;
libname exclworx "/data/shared/iic/intel_delivery/common/excls_vars/work_tables/" ; /*  work storage while exclusion tables are being built  */
libname excltemx "/data/shared/iic/intel_delivery/common/excls_vars/base_tables/" ; /*  temp storage while exclusion tables are being built  */
libname camexclx  "/data/shared/iic/intel_delivery/common/excls_vars/"             ; /*  final destination for exclusion tables               */
libname b10debtx  "/data/shared/iic/intel_delivery/collections/b10/2017/sasdata";


/*********************************************************************************************************************************/
/*Set the connection to the DSS and TDW schema in EDW.  As well as DW   READBUFF set to maximum
/*********************************************************************************************************************************/
LIBNAME DSS ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP SCHEMA='DSS' READBUFF=32687;
LIBNAME TDW ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP SCHEMA='TDW' READBUFF=32687;
LIBNAME DW  ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP              READBUFF=32687 INSERTBUFF=32687 DBCOMMIT=32687;
LIBNAME DSSMART ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP SCHEMA='DSSMART' READBUFF=32687 INSERTBUFF=32687 DBCOMMIT=32687;
LIBNAME SUMMARY ORACLE USER="&ORADW_USER1" PASSWORD="&ORADW_PASS1" PATH=DWP SCHEMA='SUMMARY' READBUFF=32687 INSERTBUFF=32687 DBCOMMIT=32687;
