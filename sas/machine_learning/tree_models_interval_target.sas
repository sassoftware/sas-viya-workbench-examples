/******************************************************************************
EXAMPLE:             Tree Based Modeling for Interval Target
DATA:                bike_sharing_demand.csv
DATA SOURCE:         Fanaee-T, H. (2013). Bike Sharing Dataset. UCI Machine Learning Repository. https://doi.org/10.24432/C5W894
DESCRIPTION:         This template demonstrates a workflow for building predictive models in SAS using Tree based modeling.
PURPOSE:             The data contains information about the number of bikes rented per hour in a bike sharing system over two years.
                     The models in this workflow predict the number of bikes rented per hour using various predictor variables,
                     such as weather, season, temperature, hour, month, and weekday.
DETAILS:
                    - Models built include: Decision Tree, Forest, and Gradient Boosting.
                    - The data is partitioned prior to model execution.  This differs from linear_svm_models_interval_target.sas,
                      where the data is partitioned during model execution.
                    - The fit statistic for each model is generated and extracted when the models execute.
                    - Model Assessment: The top five variables selected per model are plotted.
                    - Model Comparison: The Average Square Error (ASE) is plotted for a visual comparison.
******************************************************************************/

/* Set title */
title 'Tree Based Modeling for an Interval Target';

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
  Partition the data into a 40/30/30 Train/Validate/Test split.
    -The output partitioned data contains a derived indicator column (_PartInd_)
     for identifying each row as in a Train (1), Validate (0), or Test (2) partition.
    -The Training and Validation partitions are used to train the models.
    -All partitions are scored to assess the models for the final model comparison.
 ******************************************************************************/
title2 'Data Partitioning';
proc partition data=bikeSharing seed=12345 partind samppct=40 samppct2=30;
    output out=bikeSharingPart;
run;

/******************************************************************************
  Build three tree-based models for prediction and scoring:
    - Decision Tree
    - Forest
    - Gradient Boosting
  The Partition statement identifies the Training/Validation/Test partitions
  in the data.
  The partitions are used for sub-tree selection during training, and for the
  calculation of fit statistics.  The final model fit statistic (ASE) for all
  partitions is output with the ODS statement.
******************************************************************************/
/* Define Class input variables */
%let class_vars=season holiday workingday weather weekday month year hour;

/* Define Interval input variables */
%let int_vars=temp humidity windspeed;

/* Decision Tree */
title2 'Decision Tree Model';
proc treesplit data=bikeSharingPart;
    class &class_vars.;
    model count=&class_vars. &int_vars.;
    prune reducederror;
    /* Identify the Train/Validate/Test partitions that exist in the data. */
    /* The partitions are used for sub-tree selection during training, and for calculation of fit statistics. */
    partition rolevar=_PartInd_(train='1' validate='0' test='2');
    ods output TreePerformance=fit_tree VariableImportance=treeimp;
run;

/* Forest */
title2 'Forest Model';
proc forest data=bikeSharingPart seed=12345 ntrees=100;
    input &class_vars. / level=nominal;
    input &int_vars. / level=interval;
    target count / level=interval;
    /* Identify the Train/Validate/Test partitions that exist in the data. */
    partition rolevar=_PartInd_(train='1' validate='0' test='2');
    ods output FitStatistics=fit_forest(where=(trees=100) rename=(ASETrain=Training ASEValid=Validation ASETest=Test))
        VariableImportance=forestimp;
run;

/* Transpose so that the statistics from the three models can be combined. */
proc transpose data=fit_forest out=forestTranspose(rename=(col1=ASE)) name=dataset;
  var Training Validation Test;
run;

/* Gradient Boosting */
title2 'Gradient Boosting Model';
proc gradboost data=bikeSharingPart seed=12345 ntrees=100;
    input &class_vars. / level=nominal;
    input &int_vars. / level=interval;
    target count / level=interval;
    /* Identify the Train/Validate/Test partitions that exist in the data. */
    partition rolevar=_PartInd_(train='1' validate='0' test='2');
    ods output FitStatistics=fit_gb(where=(trees=100) rename=(ASETrain=Training ASEValid=Validation ASETest=Test))
        VariableImportance=gbimp;
run;

proc transpose data=fit_gb out=gbTranspose(rename=(col1=ASE)) name=dataset;
  var Training Validation Test;
run;

/******************************************************************************
  Model Assessment - Combine the model variable importance data and generate a
  bar chart plot of the top five selected variables per model. Here, Variable
  'hour' (the hour of the day at the start of the rental period), is by far the
  the most important variable in all three models, followed by Variable 'temp'
  (the temperature at the start of the rental period).
 ******************************************************************************/
data importance;
    length source $ 17;
    label source='Model';
    set treeimp(in=t obs=5) forestimp(in=f obs=5) gbimp(in=g obs=5);
    if t then source='Decision Tree';
    else if f then source='Forest';
    else if g then source='Gradient Boosting';
run;

title2 'Variable Importance by Model';
proc sgplot data=importance;
   vbar source / response=RelativeImportance barwidth=1 group=variable groupdisplay=cluster categoryorder=respdesc;
   xaxis display=(nolabel noline noticks);
   yaxis grid;
run;

/******************************************************************************
  Model Comparison - Combine the model ASE fit statistics and generate a bar chart
  plot for visual comparison.  This comparison shows that the Gradient Boosting model
  performed the best with the lowest ASE.
 ******************************************************************************/
data fit;
    length source $ 17;
    label ase='Average Squared Error' dataset='Partition' source='Model';
    set fit_tree(in=t) forestTranspose(in=f) gbTranspose(in=g);
    if t then source='Decision Tree';
    else if f then source='Forest';
    else if g then source='Gradient Boosting';
run;

title2 'Model Comparison (ASE)';
proc sgplot data=fit;
   vbar source / response=ase barwidth=1 group=dataset groupdisplay=cluster;
   xaxis display=(nolabel noline noticks);
   yaxis grid;
   keylegend / noborder;
run;

/******************************************************************************
  This example illustrated a workflow for constructing predictive models in SAS
  utilizing tree-based modeling techniques for an interval target, followed by
  model assessment and comparison.
******************************************************************************/

/* Clear title. */
title;