/******************************************************************************
EXAMPLE:             Tree Based Modeling for Class Target
DATA:                adult_train.csv, adult_test.csv
Data Sources:        Becker, B. and Kohavi, R. (1996). Adult. UCI Machine Learning Repository. https://doi.org/10.24432/C5XW20.
DESCRIPTION:         This template demonstrates a workflow for building predictive models in SAS using tree-based modeling.
PURPOSE:             The goal is to predict the likelihood of a binary outcome using various predictor variables through tree-based modeling techniques.
                     In this case, it predicts whether income exceeds $50K/yr.
DETAILS:
                    - Models built include: Decision Tree, Forest, and Gradient Boosting.
                    - Demonstrate different ways to score the test data.
                    - Model Assessment: The frequency of actual versus predicted events is tabulated for each model.
                    - Model Comparison: ROC curves are plotted to assess the performance of each model in predicting events.
******************************************************************************/


/* Set title */
title 'Tree Based Modeling for Class Target';

/******************************************************************************
Read the input data
******************************************************************************/

/* Import train and test data */
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

/* Display first 10 rows of adult_train data */
title2 'First 10 rows of adult data';
proc print data=adult_train(obs=10);
run;

/******************************************************************************
Build multiple models for prediction and scoring the test partition
- Decision Tree
- Gradient Boosting
- Forest
******************************************************************************/
/* Define Class type Variables */
%let class_vars = workclass education marital_status occupation relationship race sex native_country;

/* Define Interval type Variables */
%let int_vars = age fnlwgt education_num capital_gain capital_loss hours_per_week;

/* Build Decision Tree model */
title2 'Decision Tree Model';
proc treesplit data=adult_train maxdepth=5 assignmissing=useinsearch seed=12345;
    class target &class_vars;
    model target= &int_vars &class_vars ;
    /* Requests cost-complexity pruning */
    prune costcomplexity;
    /* Partition dataset into disjoint subsets for model training and validation */
    partition fraction(validate=0.3 seed=12345);
    /*Generate score code be saved to a file */
    code file='treescore.sas';
run;

/* Scoring test data using a Decision Tree with DATA step code approach */
title2 'Scoring test data with a Decision Tree model using SAS Data Step';
data decision_tree_scored (keep=target I_target P_target_50K);
   set adult_test;
   %include 'treescore.sas';
run;

/* Build Gradient Boosting model */
title2 'Gradient Boosting Model';
proc gradboost data=adult_train seed=12345 ntrees=100 assignmissing=useinsearch;
    /* Define input variables */
    input &int_vars / level=interval;
    input &class_vars / level=nominal;
    target target /level=nominal;
    /* Partition dataset into disjoint subsets for model training and validation */
    partition fraction(validate=0.3 seed=12345);
    ods output FitStatistics=fitstats;
    savestate rstore=gbstore;
run;

/* Scoring test data using a Gradient Boosting with ASTORE approach */
title2 'Scoring test data with the Gradient Boosting model using ASTORE';
proc astore;
    score data=adult_test out=gradient_boost_scored rstore=gbstore copyvar=target;
quit;

/* Build Forest model */
title2 'Forest Model';
proc forest data=adult_train seed=12345 ntrees=100 assignmissing=useinsearch;
    /* Define input variables */
    input &int_vars / level=interval;
    input &class_vars / level=nominal;
    target target /level=nominal;
    /* Partition dataset into disjoint subsets for model training and validation */
    partition fraction(validate=0.3 seed=12345);
    savestate rstore=foreststore;
run;

/* Score test data using the Forest model with ASTORE approach */
title2 'Scoring test data with the Forest model using ASTORE ';
proc astore;
    describe rstore=foreststore;
    score data=adult_test out=forest_scored rstore=foreststore copyvar=target;
quit;

/******************************************************************************
Model Assessment and Comparison:
- The frequency of actual versus predicted events is tabulated for each model.
- ROC curves are plotted to assess the performance of each model in predicting events.
******************************************************************************/

/* Define a reusable function to generate a confusion matrix for each of the three models in a loop */
%let models = decision_tree gradient_boost forest;
%macro model_assessment(model, in_data);
    title2 "Model Assessment on Scored Data: &model";
    proc freq data=&in_data.;
       tables target*I_target / chisq measures;
    run;
%mend;

/* Loop through each model */
%macro run_model_assessment;
    %do i = 1 %to %sysfunc(countw(&models));
        %let model_name = %scan(&models, &i);
        %put &model_name.;
        %model_assessment(&model_name, &model_name._scored);
    %end;
%mend;

/* Executes the model_assessment for each model */
%run_model_assessment;

/******************************************************************************
Model Comparison for Tree-Based Models
******************************************************************************/

/* Combine predictions from all tree models for ROC plotting */
data roc_data (keep = target P_target_50K source);
    set decision_tree_scored (in=_dt) gradient_boost_scored (in=_gb) forest_scored (in=_fs);
    if _dt then source = 'Decision Tree';
    else if _gb then source = 'Gradient Boost';
    else if _fs then source = 'Forest';
run;

/* Calculates ROC information */
proc assess data = roc_data rocout=roc_data;
    var P_target_50K;
    target target / event=">50K" level=nominal;
    by source;
run;

/* Plot ROC curve for all models */
proc sgplot data=roc_data;
    title2 'ROC Curve by Model';
    series x=_FPR_ y=_Sensitivity_ / group=source markers;
    xaxis label='False Positive Rate';
    yaxis label='True Positive Rate';
run;

/******************************************************************************
This example illustrated a workflow for constructing predictive models in SAS
utilizing tree-based modeling techniques, followed by comprehensive model assessment and comparison.
******************************************************************************/
