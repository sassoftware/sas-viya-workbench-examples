/******************************************************************************

 EXAMPLE:     logistic_banking.sas
 DATA:        banking
 DESCRIPTION: The data is related with direct marketing campaigns. The goal is
              to predict if the client will subscribe a term deposit.
 PURPOSE:     In this example, we demonstrate to users who are familiar with
              SAS® programming and functionality that they can still use
              them in SAS® Viya® Workbench.  In addition, they can use
              the next-generation Viya procedures with minimal code changes and
              no need for a separate cloud-based server.

 ******************************************************************************/

title 'Build logistic regression models with both LOGISTIC and LOGSELECT procedures';

/******************************************************************************

 Load the banking data and show that the data is ready for use.

 ******************************************************************************/

options nosource;
proc import datafile="&WORKSPACE_PATH./data/banking.csv"
   out=banking dbms=csv replace;
run;
options source;

title2 'Portion of banking data';
proc print data=banking(obs=10);
run;


/******************************************************************************

 Use the LOGISTIC procedure to fit a regression model for the BANKING data.

 ******************************************************************************/

title2 'LOGISTIC on banking data';
proc logistic data=banking;
   class job_admin--poutcome_success;
   model y = age duration campaign pdays previous emp_var_rate cons_price_idx
         cons_conf_idx euribor3m nr_employed job_admin--poutcome_success /tech=nr gconv=1e-7;
run;


/******************************************************************************

 We can use one of the new generation procedures, LOGSELECT, with minimal
 changes to the procedure syntax.

 ******************************************************************************/

title2 'LOGSELECT on banking data';
proc logselect data=banking;
    class job_admin--poutcome_success;
    model y = age duration campaign pdays previous emp_var_rate cons_price_idx
          cons_conf_idx euribor3m nr_employed job_admin--poutcome_success;
    selection method=NONE;
run;


/******************************************************************************

 We can add additional parameters to the LOGSELECT procedure if we want to
 match the results from the LOGISTIC procedure.

 ******************************************************************************/

title2 'LOGSELECT on banking data with specified parameters to match LOGISTIC results';
proc logselect data=banking  technique=nrridg gconv=1e-7 fconv=1e-7 absfconv=1e-7
               absgconv=1e-7 maxiter=300;
    class job_admin--poutcome_success;
    model y = age duration campaign pdays previous emp_var_rate cons_price_idx
          cons_conf_idx euribor3m nr_employed job_admin--poutcome_success;
    selection method=NONE;
run;


/******************************************************************************

 A short summary of the key results from the LOGISTIC and LOGSELECT procedures.

 From LOGISTIC:
 Model Fit Statistics
 Criterion      Intercept Only	  Intercept and Covariates
 -2 Log L       28998.724         17077.827
 AIC            29000.724         17183.827

 From LOGSELECT:
 Fit Statistics
 -2 Log Likelihood            17078
 AIC (smaller is better)      17184

 ******************************************************************************/

/******************************************************************************

In summary, for SAS customers who are familiar with SAS procedure code
 and functionality, it is not complicated to transition to use newer
 generation procedures.

 ******************************************************************************/
title;