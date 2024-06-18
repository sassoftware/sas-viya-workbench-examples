/******************************************************************************

 EXAMPLE:     gradientboosting_students.sas
 DATA:        students_train, students_test
 DESCRIPTION: This data set contains student enrollment information. The goal
              is to analyze what factors could impact a student's drop out
              rate.
 PURPOSE:     This example shows how to build a classification tree model using
              the GRADBOOST procedure without the need to use a separate
              cloud-based server. It also demonstrates the use of analytic
              stores as a mechanism for saving models and scoring them.

 ******************************************************************************/

 title 'Build a gradient boosting tree model with the GRADBOOST procedure for the students data';

/******************************************************************************

 Load the training and test data and show that the data is ready for use.

 ******************************************************************************/

options nosource;
proc import
    datafile="&WORKSPACE_PATH./data/students_train.csv"
    out=students_train dbms=csv replace;
run;
proc import
    datafile="&WORKSPACE_PATH./data/students_test.csv"
    out=students_test dbms=csv replace;
run;
options source;

title2 'Portion of students_train input data';
proc print data=students_train(obs=10);
run;

/******************************************************************************

 Since the data is now available for the SAS procedures to use, we are ready
 to start the analysis. We will start by building a gradient boosting tree on
 the students data set and save the model as an analytic store.

******************************************************************************/

title2 'GRADBOOST on students_train data';
proc gradboost data=students_train ntrees=100 assignmissing=useinsearch;
    input Maritalstatus ApplicationMode Course AttendTime PreQualification Nationality
          Qualification_Mom Qualification_Dad Occupation_Mom Occupation_Dad Displaced
          SpecialNeed Debtor TuitionFee Gender Scholarship International / level=nominal;
    input ApplicationOrder PreQualGrade AdmissionGrade EnrollmentAge
          Curricular_Credited_1st Curricular_Enrolled_1st Curricular_Eval_1st
          Curricular_Approved_1st Curricular_Grade_1st Curricular_NoEval_1st
          Curricular_Credited_2nd Curricular_Enrolled_2nd Curricular_Eval_2nd
          Curricular_Approved_2nd Curricular_Grade_2nd Curricular_NoEval_2nd
          Unemployment Inflation GDP / level=interval;
    target target / level=nominal;
    savestate rstore=gbstore;
run;


/******************************************************************************

 Describing the astore gives us information about the model.  We then use it
 to score the test data and save the result in the STUDENTS_SCOREOUT data set.
 A sample of the results are printed.

******************************************************************************/

title2 'ASTORE describe and scoring';
proc astore;
    describe rstore=gbstore;
    score data=students_test rstore=gbstore
          out=students_scoreout copyvars=(target);
run;

proc print data=students_scoreout(obs=5);
run;

/******************************************************************************

 Astores can be saved as files for use in subsequent programs or entirely
 different environments.

 ******************************************************************************/

title2 'Saving the astore into a file';
proc astore;
    download rstore=gbstore store="/tmp/gbstore.sasast";
run;


/******************************************************************************

 To replicate this, we will reload it under a new name, describe it to see that
 nothing has changed, and then score the test data against it again.

 ******************************************************************************/

title2 'Reloading the astore and scoring it';
proc astore;
    upload rstore=gbstore2 store="/tmp/gbstore.sasast";
    describe rstore=gbstore2;
    score data=students_test rstore=gbstore2 out=students_scoreout2;
run;

proc print data=students_scoreout2(obs=5);
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