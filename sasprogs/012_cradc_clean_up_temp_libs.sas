/**********************************************************************
Project: 	  Data & Intelligence Platform - Heritage

Program Name: 012_cradc_clean_up_temp_libs.sas

Overview:     
              
***********************************************************************
                  DEPENDENCIES AND LIMITATIONS
      
 
Parameter(s):  None

Dependencies:  None


***********************************************************************
                    CHANGE CONTROL LOG 

Change log (in reverse chronological order) :-

June2019  	KM  Migration to DIP
            Original module was 18_Clean_Up_Temp_Libs.sas
            Uncommented calls to proc datasets to kill temp libraries
2015-2019  	Original CRADC development on Heritage Platform by
            Richard Holley and members of the Analytics Team.
            	 
                                      
***********************************************************************/

/************************************************************************************************************************/
/*                                 _____  _                       _    _                                                */
/*                                / ____|| |                     | |  | |                                               */
/*                               | |     | |  ___   __ _  _ __   | |  | | _ __                                          */
/*                               | |     | | / _ \ / _` || '_ \  | |  | || '_ \                                         */
/*                               | |____ | ||  __/| (_| || | | | | |__| || |_) |                                        */
/*                                \_____||_| \___| \__,_||_| |_|  \____/ | .__/                                         */
/*                                                                       | |                                            */
/*                                                                       |_|                                            */
/************************************************************************************************************************/
/*                                                                                                                      */
/*                                 This section MUST be at the end of the scheduled code.                               */
/*                                                                                                                      */
/************************************************************************************************************************/
/*  Kill all the temporary data sets
/************************************************************************************************************************/
/*proc datasets lib=cradcwrk kill nodetails nolist; RUN; QUIT;*/
/*proc datasets lib=edw_curr kill nodetails nolist; RUN; QUIT;*/
/*proc datasets lib=tdw_curr kill nodetails nolist; RUN; QUIT;*/
/*proc datasets lib=did_tmp  kill nodetails nolist; RUN; QUIT;*/
/**/
/*LIBNAME cradcwrk CLEAR;*/
/*LIBNAME edw_curr CLEAR;*/
/*LIBNAME tdw_curr CLEAR;*/
/*LIBNAME did_tmp  CLEAR;*/




/************************************************************************************************************************/
/*                           _______  _             ______             _                        __                      */
/*                          |__   __|| |           |  ____|           | |           _           \ \                     */
/*                             | |   | |__    ___  | |__    _ __    __| |          (_)  ______   | |                    */
/*                             | |   | '_ \  / _ \ |  __|  | '_ \  / _` |              |______|  | |                    */
/*                             | |   | | | ||  __/ | |____ | | | || (_| |           _            | |                    */
/*                             |_|   |_| |_| \___| |______||_| |_| \__,_|          (_)           | |                    */
/*                                                                                              /_/                     */
/*                                                                                                                      /*
/************************************************************************************************************************/
