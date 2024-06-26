/******************************************************************************
EXAMPLE:             Linear Regression and SVM modeling for Interval Target
DATA:                bike_sharing_demand.csv
DATA SOURCE:         Fanaee-T, H. (2013). Bike Sharing Dataset. UCI Machine Learning Repository. https://doi.org/10.24432/C5W894
DESCRIPTION:         This template demonstrates a workflow for building predictive models in SAS using Linear Regression and SVM modeling.
PURPOSE:             The data contains information about the number of bikes rented per hour in a bike sharing system over two years.
                     The models in this workflow predict the number of bikes rented per hour (count) using various predictor variables,
                     such as weather, season, temperature, hour, month, and weekday.
DETAILS:
                    - Models built include: Linear Regression, Support Vector Machine (SVM), and Ensemble.
                      Note that Support Vector Machine with an interval target is often referred as
                      Support Vector Regression (SVR).
                    - Treat Outliers - The target variable 'count' is highly skewed. To address this,
                      a logarithmic transformation is applied.
                    - Variable Selection is accomplished for the input variables to SVM.  This is not required for
                      Linear Regression since it incorporates variable selection during model training.
                    - The data is partitioned during model execution.  This differs from tree_models_interval_target.sas,
                      where the data is partitioned prior to model execution.
                    - The models output scored data when they execute.
                    - Model Assessment and Comparison - Models are assessed by plotting the predicted by target means,
                      and compared by plotting the Average Squared Error (ASE) statistic.
******************************************************************************/

/* Set title */
title 'Linear Regression and SVM Modeling for an Interval Target';

/******************************************************************************
  Read the input data
 ******************************************************************************/
/* Import the data. */
options nosource;
proc import
    datafile="&WORKSPACE_PATH./sas-viya-workbench-examples/data/bike_sharing_demand.csv"
    out=bikeSharing dbms=csv replace;
run;
options source;

/******************************************************************************
  Treat Outliers - Apply the Log transformation to 'count' to treat outliers,
  as its distribution is highly skewed.
 ******************************************************************************/
data bikeSharingLog;
  set bikeSharing;
  logCount = log(count);
run;

/******************************************************************************
  Since SVM doesn't include variable selection, perform supervised variable
  selection such that variables selected jointly explain the maximum amount
  of variance contained in the target (logCount).
 ******************************************************************************/
/* Define Class input variables */
%let class_vars=season holiday workingday weather weekday month year hour;
/* Define Interval input variables */
%let int_vars=temp humidity windspeed;

/* Supervised Variable Selection */
/* Variable (Effect) selection stops when the incremental gain in explained variance is less than 0.003. */
title2 'Variable Selection';
proc varreduce data=bikeSharingLog;
    class &class_vars.;
    reduce supervised logCount=&class_vars. &int_vars. / minvarianceincrement=0.003;
    /* Output the selected effects and iteration information. */
    ods output SelectedEffects=effects SelectionSummary=summary;
run;

/* Plot the cumulative variance explained per parameter iteration. */
title2 'Iteration Plot - Proportion of Variance Explained ';
proc sgplot data=summary;
   vbar iteration / response=varexp datalabel=parameter barwidth=1;
run;

/* Create variable lists with the selected class and interval input variables. */
proc sql noprint;
    select variable into :selected_class separated by ' '
    from effects
    where type='CLASS';
    select variable into :selected_int separated by ' '
    from effects
    where type='INTERVAL';
quit;

%put Selected Class Variables: &selected_class.;
%put Selected Interval Variables: &selected_int.;

/******************************************************************************
  Build models for prediction and scoring:
    - Linear Regression
    - Support Vector Machine (SVM)
    - Ensemble
  The Partition statement is used in each case to partition the data for
  training and assessment. The Seed option ensures that the same partitions
  are used for both models. An Output statement is used to score the data for
  assessment.
******************************************************************************/
/* Linear Regression model - Forward selection is used for Variable Selection.*/
title2 'Linear Regression';
proc regselect data=bikeSharingLog;
    class &class_vars.;
    model logCount=&class_vars. &int_vars.;
    selection method=forward;
    /* The data is partitioned during model execution into a 40/30/30 Train/Validate/Test split. */
    partition fraction(validate=0.3 test=0.3 seed=12345);
    /* Output the Parameter Estimates. */
    ods output ParameterEstimates=estimates;
    output out=score_reg copyvars=(logCount date hour) role predicted=P_logCount;
run;

/* Prepare the Parameter Estimates (Regression Coefficients) for plotting the t Values. */
Proc sql;
    create table estimatesT as
    select parameter, abs(tvalue) as tValue label='t Value'
    from estimates;
quit;

/* Plot the parameters by descending absolute t Value.  Larger values indicate more
  significant parameters. */
title2 'Linear Regression - t Values by Parameter';
proc sgplot data=estimatesT;
    vbar parameter / response=tvalue barwidth=1 categoryorder=respdesc;
run;

/* Support Vector Machine model (SVR training) - use the selected class and interval variables. */
title2 'Support Vector Machine (SVM)';
proc svmachine data=bikeSharingLog;
    input &selected_class. / level=nominal;
    input &selected_int. / level=interval;
    target logCount / level=interval;
    /* The data is partitioned during model execution into a 40/30/30 Train/Validate/Test split. */
    partition fraction(validate=0.3 test=0.3 seed=12345);
    output out=score_svm copyvars=(logCount date hour) role;
run;

/* Ensemble model - Take the mean of the predicted values for Linear Regression and SVM. */
proc sql;
    Create table ensemble as
    select r.logCount, mean(r.P_logCount,s.P_logCount) as P_logCount, r._role_
    from score_reg r, score_svm s
    where r.date = s.date
      and r.hour = s.hour
    order by r.date, r.hour;
quit;

/* Format for translating _role_ to 'Training', 'Validation', and 'Testing'. */
proc format;
  value role 1='Training' 2='Validation' 3='Testing';
run;

/* Append the data predictions for all models into one data set. */
data combine;
    label _role_='Partition' source='Model';
    format _role_ role.;
    set score_svm(in=svm) score_reg(in=reg) ensemble;
    if svm then source='Support Vector Machine';
    else if reg then source='Linear Regression';
    else source='Ensemble';
run;

/******************************************************************************
  Model Assessment - Examine how the models performed using a predicted by target
  comparison on the Validation partition.
 ******************************************************************************/
/* Calculate the demi-decile mean predicted/target values for the Validation partition. */
proc assess data=combine nbins=20 ncuts=100 method=exact liftout=lift;
    by source;
    where _role_=2;
    input P_logCount;
    target logCount / level=interval;
run;

/* Plot the Predicted target to Actual target mean values at the 5 percentiles.*/
/* Plotted values close to the x=y line denote a better model. */
title2 'Model Assessment - Predicted by Actual Log Count (Validation Data)';
proc sgplot data=lift;
   series x=_MeanT_ y=_MeanP_ / group=source groupdisplay=overlay;
   lineparm x=1.3 y=1.3 slope=1 / legendlabel="x=y";
   yaxis grid;
   keylegend / noborder;
run;

/******************************************************************************
  Model Comparison - Compare the Average Squared Error fit across the models.
  This comparison shows that the Linear Regression model performed the best with
  the lowest ASE.
 ******************************************************************************/
/* Calculate the ASE for both models, grouped by model and partition role. */
proc assess data=combine fitstatout=fit;
    by source _role_;
    input P_logCount;
    target logCount / level=interval;
run;

title2 'Model Comparison (ASE)';
proc sgplot data=fit;
   vbar source / response=_ase_ barwidth=1 group=_role_ groupdisplay=cluster;
   xaxis display=(nolabel noline noticks);
   yaxis grid;
   keylegend / noborder;
run;

/******************************************************************************
  This example demonstrated a workflow for building predictive models
  in SAS for an interval target. It accomplished target transformation, variable
  selection, predictive modeling with Linear Regression, SVM, and Ensemble models,
  and model comparison/evaluation.
******************************************************************************/

/* Clear title. */
title;