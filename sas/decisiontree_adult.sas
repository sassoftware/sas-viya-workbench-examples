/******************************************************************************

 EXAMPLE:     decisiontree_adult.sas
 DATA:        adult_train, adult_test
 DESCRIPTION: This is a census income data set. The goal is to predict whether
              an individual's income exceeds $50,000 per year.
 PURPOSE:     This example shows how to build a classification tree model using
              the TREESPLIT procedure without the need to use a separate
              cloud-based server. It also demonstrates the use of analytic
              stores as a mechanism for saving models and scoring them.

 ******************************************************************************/

 title 'Build a classification tree model with the TREESPLIT procedure for the Adult data';

/******************************************************************************

 Load the training and test data and show that the data is ready for use.

 ******************************************************************************/

options nosource;
proc import
    datafile="&WORKSPACE_PATH./sas-viya-workbench-examples/data/adult_train.csv"
    out=adult_train dbms=csv replace;
run;
proc import
    datafile="&WORKSPACE_PATH./sas-viya-workbench-examples/data/adult_test.csv"
    out=adult_test dbms=csv replace;
run;
options source;

title2 'Portion of adult_train input data';
proc print data=adult_train(obs=10);
run;


/******************************************************************************

 Since the data is now available for the SAS® analytic procedures to use,
 we are ready to start the analysis. We will start by building a decision
 tree on the ADULT_TRAIN data set and save the model as an analytic store.

******************************************************************************/

title2 'TREESPLIT on adult_train data';
proc treesplit data=adult_train seed=12345;
    input age fnlwgt education_num  capital_gain
          capital_loss hours_per_week / level=interval;
    input workclass education marital_status occupation
          relationship race sex native_country / level=nominal;
    target target /level=nominal;
    savestate rstore=dtstore;
run;


/******************************************************************************

 Describing the astore gives us information about the model. We then use it
 to score the test data and save the result in the ADULT_SCOREOUT data set.
 A sample of the results are printed.

******************************************************************************/

title2 'ASTORE describe and scoring';
proc astore;
    describe rstore=dtstore;
    score data=adult_test rstore=dtstore out=adult_scoreout;
run;

proc print data=adult_scoreout(obs=5);
run;


/******************************************************************************

 Astores can be saved as files for use in subsequent programs or entirely
 different environments.

 ******************************************************************************/

title2 'Saving the astore into a file';
proc astore;
    download rstore=dtstore store="/tmp/dtstore.sasast";
run;


/******************************************************************************

 To replicate this, we will reload it under a new name, describe it to see that
 nothing has changed, and then score the test data against it again.

 ******************************************************************************/

title2 'Reloading the astore and scoring it';
proc astore;
    upload rstore=dtstore2 store="/tmp/dtstore.sasast";
    describe rstore=dtstore2;
    score data=adult_test rstore=dtstore2 out=adult_scoreout2;
run;

proc print data=adult_scoreout2(obs=5);
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