/******************************************************************************
EXAMPLE:             Linear and SVM based Modeling for Class Target
DATA:                adult_train.csv, adult_test.csv
Data Sources:        Becker, B. and Kohavi, R. (1996). Adult. UCI Machine Learning Repository. https://doi.org/10.24432/C5XW20.
DESCRIPTION:         This template demonstrates an workflow for building predictive models in SAS using Linear, SVM and Ensemble modeling.
PURPOSE:             The goal is to predict the likelihood of a binary outcome using various predictor variables through Linear and SVM based modeling techniques.
                     In this case, it predicts whether income exceeds $50K/yr.
DETAILS:
                    - Models built include: Logistic Regression and Support Vector Machines (SVM) and Ensemble
                    - Demonstrate different ways to score the test data.
                    - Model Comparison- ROC curves are plotted to assess the performance of each model in predicting events.
******************************************************************************/

/* Set title */
title 'Linear and SVM Based Modeling for Class Target';

/******************************************************************************
Read the input data.
******************************************************************************/

/* Import data */
options nosource;
/* Training dataset */
proc import
    datafile="&WORKSPACE_PATH./data/adult_train.csv"
    out=adult_train dbms=csv replace;
run;

/* Test dataset */
proc import
    datafile="&WORKSPACE_PATH./data/adult_test.csv"
    out=adult_test dbms=csv replace;
run;
options source;

/* Display first 10 rows of data */
title2 'First 10 rows of adult data';
proc print data=adult_train(obs=10);
run;

/******************************************************************************
Insert missing values in the training partition for select interval variables
to demonstrate imputation technique, as the original data contains no missing values.
******************************************************************************/

data _adult_train;
    set adult_train;
    /* Randomly insert missing values in desired interval variables */
    /* Example: Set missing values for the 'age' variable with a 2% probability */
    if ranuni(0) < 0.02 then age = .;
    /* Example: Set missing values for the 'hours_per_week' variable with a 3% probability */
    if ranuni(0) < 0.03 then hours_per_week = .;
run;

title2 'Summary of missing values';
proc means data=_adult_train n nmiss mean min max;
run;

/******************************************************************************
Perform data imputation.
******************************************************************************/

title2 'Imputation on adult income data using mean';
proc stdize data=_adult_train out=adult_train_imputed reponly missing=mean method=mean;
    var age hours_per_week;
run;

title2 'Summary of imputed values';
proc means data=adult_train_imputed n nmiss mean min max;
run;

/* Define Class type Variables */
%let class_vars = workclass education marital_status occupation relationship race sex native_country;

/* Define Interval type Variables */
%let int_vars = age fnlwgt education_num capital_gain capital_loss hours_per_week;

/******************************************************************************
Perform Variable selection/Variable Reduction.
******************************************************************************/

title2 'Variable Selection/Reduction';
proc varreduce data=adult_train_imputed matrix=COV tech=DSC;
   ods output SelectionSummary=variable_selection_summary SelectedEffects=variable_selected;
   class target &class_vars;
   reduce supervised target= &class_vars &int_vars / maxiter=15 BIC;
run;

/* Plot the BIC values over iterations during the variable selection process */
proc sgplot data=variable_selection_summary;
   series x=Iteration  y=BIC;
run;

/* Capture selected variables */
proc sql noprint;
    select variable into :selected_class separated by ' '
    from variable_selected
    where type = 'CLASS';

    select variable into :selected_int separated by ' '
    from variable_selected
    where type = 'INTERVAL';
quit;

%put Selected Class Variables: &selected_class;
%put Selected Interval Variables: &selected_int;

/******************************************************************************
Build multiple models for prediction
- Logistic regression
- Support vector machine
Predictions from these models are used to create an ensemble model.
******************************************************************************/

/*
   Logistic Regression Model using PROC LOGSELECT with Variable Selection.
   All available variables are utilized for model training, as PROC LOGSELECT performs variable selection to identify the most relevant ones.
*/

title2 'Logistic Regression Model';
proc logselect data=adult_train_imputed;
    class &class_vars;
    model target(event='>50K')=&class_vars &int_vars;
    partition fraction(validate=0.3 seed=12345);
    /* Specify variable selection technique*/
    selection method=stepwise;
    /* Generate score code */
    code file='logscore.sas';
run;

/* Scoring test data with the LOGSELECT model using SAS Data Step */
title2 'Scoring test data using SAS Data Step';
data log_scored ;
   set adult_test;
   %include 'logscore.sas';
run;

/******************************************************************************
This code snippet constructs a Support Vector Machine (SVM) model in SAS.
Leveraging the shortlisted variables from PROC VARREDUCE to guide model training.
******************************************************************************/

title2 'SVM Model';
proc svmachine data=adult_train_imputed c=0.5 maxiter=20 tolerance=0.0001;
    /* Define input variables */
    input &selected_int / level=interval;
    input &selected_class / level=nominal;
    target target / level=nominal;
    partition fraction(validate=0.3 seed=12345);
    savestate rstore=svmstore;
run;

/* Score test data with the SVM model using ASTORE approach*/
title2 'Scoring test data with the SVM model using ASTORE';
proc astore;
    score data=adult_test out=svm_scored rstore=svmstore copyvar=target;
quit;

/******************************************************************************
Create Ensemble Model by combining Logistic Regression and SVM predictions.
Ensemble predictions are calculated as the average of logistic regression and SVM predictions.
******************************************************************************/

title2 'Ensemble Model';
data ensemble_predictions;
    merge log_scored (rename=(P_target=log_pred I_target=I_target_log) keep = target I_target P_target )
        svm_scored (rename=(P_target_50K=svm_pred I_target=I_target_svm)  keep = target I_target P_target_50K);
    /* Calculate average of predictions */
    ensemble_pred = mean(log_pred, svm_pred);
    if ensemble_pred <.50 then I_target_ensemble='<=50K';
    else I_target_ensemble='>50K';
run;

/******************************************************************************
Model comparison:
- ROC curves are plotted to assess the performance of each model in predicting events.
******************************************************************************/

ods graphics on;
proc logistic data=ensemble_predictions plots=roc;
   model target(event='>50K') = log_pred svm_pred ensemble_pred / nofit;
   roc 'Ensemble' ensemble_pred;
   roc 'Logistic Regression' log_pred;
   roc 'Support Vector Machine' svm_pred;
run;

/******************************************************************************
This example demonstrated an advanced workflow for building predictive models in SAS.
It includes data preprocessing, variable selection, building Linear, SVM and Ensemble models
and model comparison/evaluation.
******************************************************************************/

/* Clear title */
title;
