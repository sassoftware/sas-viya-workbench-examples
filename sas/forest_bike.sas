/******************************************************************************

 EXAMPLE:     forest_bike.sas
 DATA:        bike_train, bike_test
 DESCRIPTION: This data set contains the hourly and daily count of rental bikes
              with the corresponding weather and seasonal information.
 PURPOSE:     This example shows how to build a regression forest model using
              the FOREST procedure without the need to use a separate cloud-
              based server. It also demonstrates the use of analytic stores as a
              mechanism for saving models and scoring them.
 SOURCE:      Adapted from
              "EDA & Ensemble Model (Top 10 Percentile)"
              https://www.kaggle.com/code/viveksrinivasan/eda-ensemble-model-top-10-percentile/notebook
              Vivek Srinivasan

 ******************************************************************************/

title 'Built regression forest models for bike_sharing_demand data';

/******************************************************************************

 Load the input data.

 ******************************************************************************/

options nosource;
proc import
    datafile="&WORKSPACE_PATH./sas-viya-workbench-examples/data/bike_sharing_demand.csv"
    out=bike_sharing dbms=csv replace;
run;
options source;

title2 '10 rows of bike_sharing data';
proc print data=bike_sharing(obs=10);
run;


/******************************************************************************

 Partition data into training and test sets.
 It is common to split the input data into training data, for training the
 model, and test data, for scoring the model. Here, the PARTITION procedure
 is used to randomly partition the BIKE_SHARING data set into BIKE_TRAIN and
 BIKE_TEST, with 80% and 20% of the original data, respectively.

 ******************************************************************************/

title2 'Create training and test data sets with the PARTITION procedure';
proc partition data=bike_sharing seed=12345
   partind samppct=80;
   output out=bike_sharing_part;
run;

data bike_train(drop=_partind_);
   set bike_sharing_part(where=(_partind_=1));
run;

data bike_test(drop=_partind_);
   set bike_sharing_part(where=(_partind_~=1));
run;


/******************************************************************************

 Since the data is now available for the SAS analytic procedure to use,
 we are ready to start the analysis. We will start by building a regression
 forest model on the bike_sharing training data set and save the model as an
 analytic store.

******************************************************************************/

title2 'FOREST on bike_train data';
proc forest data=bike_train ntrees=100 assignmissing=useinsearch;
    target count / level=interval;
    input temp windspeed humidity hour / level=interval;
    input weekday month season workingday holiday weather / level=nominal;
    savestate rstore=foreststore;
run;

/******************************************************************************

 Describing the astore gives us information about the model.  We then use it
 to score the test data and save the result in the BIKE_SCOREOUT data set.
 A sample of the results are printed.

******************************************************************************/

title2 'ASTORE describe and scoring';
proc astore;
    describe rstore=foreststore;
    score data=bike_test rstore=foreststore
          out=bike_scoreout copyvars=(count);
run;

proc print data=bike_scoreout(obs=5);
run;


/******************************************************************************

 Astores can be saved as files for use in subsequent programs or entirely
 different environments.

 ******************************************************************************/

title2 'Saving the astore into a file';
proc astore;
    download rstore=foreststore store="/tmp/foreststore.sasast";
run;


/******************************************************************************

 To replicate this, we will reload it under a new name, describe it to see that
 nothing has changed, and then score the test data against it again.

 ******************************************************************************/

title2 'Reloading the astore and scoring it';
proc astore;
    upload rstore=foreststore2 store="/tmp/foreststore.sasast";
    describe rstore=foreststore2;
    score data=bike_test rstore=foreststore2 out=bike_scoreout2;
run;

proc print data=bike_scoreout2(obs=5);
run;


/******************************************************************************

 The example showed how we can perform SAS® Viya® analytic processes without a
 separate cloud-based server. It also demonstrated the use of saving analytic
 stores into files that can be used by any other product that supports them.
 As a result, a user can use SAS® Viya® Workbench to quickly try out ideas by
 building and testing models, which can then be saved for use in other
 environments as needed.

 ******************************************************************************/
title;