/******************************************************************************
 EXAMPLE:     classification_heart.sas
 DATA:        heart_disease.csv
 DESCRIPTION: The data set contains measurements on 304 patients, consisting
              of factors that potentially indicate the presence or absence of
              heart disease.
 PURPOSE:     In this example, we will show different binary classification
              modeling techniques to predict the heart disease.
 SOURCE:      Adapted from
              "Heart Disease prediction Random forest Classifier"
              https://www.kaggle.com/code/mruanova/heart-disease-prediction-random-forest-classifier
              Mau Rua

 ******************************************************************************/

title 'Predicting heart disease using different modeling techniques';

/******************************************************************************

 Loading the heart_disease data.

 ******************************************************************************/

options nosource;
proc import
    datafile="&WORKSPACE_PATH./sas-viya-workbench-examples/data/heart_disease.csv"
    out=heart_disease dbms=csv replace;
run;
options source;

proc format;
    value heart_disease
        0="No heart disease"
        1="With heart disease"
    ;
    value sex_format
        0="Female"
        1="Male"
    ;
run;
data heart_disease;
    format target heart_disease. sex sex_format.;
    set heart_disease;
run;


/******************************************************************************

 Print a few rows to show the original data.

 ******************************************************************************/

title2 'Portion of heart_disease data';
proc print data=heart_disease (obs=5); run;

/******************************************************************************

Column descriptions:

* age: age in years
* sex: (1 = male; 0 = female)
* cp: chest pain type
* trestbps: resting blood pressure (in mm Hg on admission to the hospital)
* chol: serum cholesterol in mg/dl
* fbs: (fasting blood sugar > 120 mg/dl) (1 = true; 0 = false)
* restecg: resting electrocardiographic results
* thalch: maximum heart rate achieved
* exang: exercise induced angina (1 = yes; 0 = no)
* oldpeak: ST depression induced by exercise relative to rest
* slope: the slope of the peak exercise ST segment
* ca: number of major vessels (0-3) colored by fluoroscopy
* thal: 3 = normal; 6 = fixed defect; 7 = reversable defect
* target: refers to the presence of heart disease in the patient (1=yes, 0=no)

 ******************************************************************************/

/******************************************************************************

 Visualization of heart disease percentages through a pie chart
 - Use the TEMPLATE procedure to customize the pie chart.
 - Use the SGRENDER procedure to display the pie chart with the customized
   template
 - Show the overall heart disease percentage and the heart disease percentage
   within sex

 ******************************************************************************/

proc template;
    define statgraph simplepie;
        begingraph;
            entrytitle "Heart Disease Percentage";
            layout region;
                piechart category=target / name="p"
                     datalabelcontent=(percent)
                     datalabellocation=inside
                     dataskin=sheen;
                discretelegend "p" / title="Target" halign=left valign=bottom;
            endlayout;
        endgraph;
    end;
run;
title2 'Percentage of heart disease in the data';
proc sgrender data=heart_disease
              template=simplepie;
run;

proc template;
    define statgraph simplepie;
        begingraph;
            entrytitle "Heart Disease Percentage";
            layout region;
                piechart category=target / group=sex name="p"
                     datalabelcontent=(percent)
                     datalabellocation=inside
                     dataskin=sheen;
                discretelegend "p" / title="Target" halign=left valign=bottom;
            endlayout;
        endgraph;
    end;
run;
title2 'Percentage of heart disease by gender in the data';
proc sgrender data=heart_disease
              template=simplepie;
run;


/******************************************************************************

 Correlation Analysis
 To better understand how different factors contribute to heart disease
 and how the factors correlate with each other, we will use two different
 visualization tools: a correlation heatmap and a pairwise scatter plot

 ******************************************************************************/

/******************************************************************************

 First, we use the CORR procedure to create the correlation matrix.

 ******************************************************************************/

title2 'Output from the CORR procedure';
ods output PearsonCorr=corr;
proc corr data = heart_disease;
    var target--fbs;
run;

/******************************************************************************

 Sort and transpose the output from the CORR procedure for plotting a heatmap.

 ******************************************************************************/

proc sort data=Corr;
    by variable;
run;
proc transpose data=Corr out=Corr_trans(rename=(COL1=Corr)) name=Correlation;
    var target--fbs;
    by variable;
run;
proc sort data=Corr_trans;
    by variable correlation;
run;


/******************************************************************************

 Use the SGPLOT procedure to produce the heatmap.
 - A few variables have strong positive or negative correlation with the "target"
   (heart disease). For example, "ca", "exang", and "oldpeak" show strong positive
   correlation with "target", while "thal" and "thalch" show strong negative
   correlation to "target".
 - Some variables also show strong correlation with each other. For example,
   "slope" has strong negative correlation with "oldpeak".

 ******************************************************************************/

title2 'Heatmap of the correlation matrix';
proc sgplot data=Corr_trans noautolegend;
    heatmap x=variable y=Correlation / colorresponse=Corr discretex discretey x2axis;
    text x=Variable y=Correlation text=Corr  / textattrs=(size=5pt) x2axis;
    label correlation='Pearson Correlation';
    yaxis reverse display=(nolabel);
    x2axis display=(nolabel);
    gradlegend;
run;

/******************************************************************************

 The next tool we can use to visualize the relationships is the pairwise
 scatter plot. We can color the plotted points by "target" to visualize
 whether different distributions exist between "with heart disease" and
 "no heart disease" on each scatter plot.

 For demonstration purposes, we pick only the variables that show strong
 correlation with "target". From the pairwise scatter plots, it is clear that
 the two groups ("With heart disease" vs "No heart disease") have different
 distribution patterns on these scatter plots.

 ******************************************************************************/

title2 'Pairwise scatter plots for interval variables';
proc sgscatter data=heart_disease;
     matrix ca exang oldpeak thal thalch /group=target diagonal=(histogram kernel);
run;

data heart_disease;
   set heart_disease;
   format target;
run;


/******************************************************************************

 Partition data into training and test sets.
 It is common to split the input data into training and test data. The
 PARTITION procedure is used to randomly partition HEART_DISEASE into
 HEART_DISEASE_TRAIN and HEART_DISEASE_TEST with an 80% to 20% ratio.

 ******************************************************************************/

title2 'Create training and test data sets with the PARTITION procedure';
proc partition data=heart_disease seed=12345
    partind samppct=80;
    output out=heart_disease_part;
run;

data heart_disease_train(drop=_partind_);
    set heart_disease_part(where=(_partind_=1));
run;

data heart_disease_test(drop=_partind_);
    set heart_disease_part(where=(_partind_~=1));
run;


/******************************************************************************

 Finally, we will show 5 different classification modeling techniques by using
 5 SAS procedures: LOGSELECT, TREESPLIT, GRADBOOST, FOREST, and SVMACHINE

 ******************************************************************************/

/******************************************************************************

 LOGSELECT procedure

 ******************************************************************************/

title2 'Build classification model using PROC LOGSELECT';
ods output FitStatistics=logfitstat;
proc logselect data=heart_disease_train technique=lbfgs maxiter=1000 partfit;
    class target ca--fbs;
    model target = age--fbs;
    savestate rstore=logstore;
run;

data _null_;
    set logfitstat;
    if rowid = 'MISCLASS' then
        call symputx('acc_train_logselect', (1-value));
run;

title3 'Score the model with ASTORE for the test data';
proc astore;
    score data=heart_disease_test rstore=logstore out=log_scoreout copyvars=(target);
run;

/***********************************
 Compute accuracy score:
 The percentage of patients in test
 data whose predicted heart disease
 status matched their actual status.
 ***********************************/
data _null_;
    retain matchSum 0;
    set log_scoreout end=last;
    match = (I_target = target);
    matchSum + match;
    if last then call symputx ('acc_test_logselect', (matchSum/_n_));
run;

/******************************************************************************

 TREESPLIT procedure

 ******************************************************************************/

title2 'Build classification model using PROC TREESPLIT';
ods output treeperformance=treestat;
proc treesplit data=heart_disease_train;
    class target ca--fbs;
    model target = age--fbs;
    prune c45;
    savestate rstore=dtstore;
run;

data _null_;
    set treestat;
    call symputx('acc_train_treesplit', (1-MiscRate));
run;

title3 'Score the model with ASTORE for the test data';
proc astore;
    score data=heart_disease_test rstore=dtstore out=dt_scoreout copyvars=(target);
run;

/***********************************
 Compute accuracy score:
 The percentage of patients in test
 data whose predicted heart disease
 status matched their actual status.
 ***********************************/
data _null_;
    retain matchSum 0;
    set dt_scoreout(keep=I_target target) end=last;
    match = (I_target = target);
    matchSum + match;
    if last then call symputx ('acc_test_treesplit', (matchSum/_n_));
run;


/******************************************************************************

 GRADBOOST procedure

 ******************************************************************************/

title2 'Build classification model using PROC GRADBOOST';
ods output FitStatistics=gbfitstat;
proc gradboost data=heart_disease_train;
    input age--oldpeak / level=interval;
    input ca--fbs / level=nominal;
    target target / level=nominal;
    savestate rstore=gbstore;
run;

data _null_;
    set gbfitstat end=last;
    if last then
       call symputx('acc_train_gradboost', (1-MiscTrain));
run;

title3 'Score the model with ASTORE for the test data';
proc astore;
    score data=heart_disease_test rstore=gbstore out=gb_scoreout copyvars=(target);
run;

/***********************************
 Compute accuracy score:
 The percentage of patients in test
 data whose predicted heart disease
 status matched their actual status.
 ***********************************/
data _null_;
    retain matchSum 0;
    set gb_scoreout(keep=I_target target) end=last;
    match = (I_target = target);
    matchSum + match;
    if last then call symputx ('acc_test_gradboost', (matchSum/_n_));
run;

/******************************************************************************

 FOREST procedure

 ******************************************************************************/

title2 'Build classification model using PROC FOREST';
ods output modelInfo=forestModel;
proc forest data=heart_disease_train;
    input age--oldpeak / level=interval;
    input ca--fbs / level=nominal;
    target target / level=nominal;
    savestate rstore=forstore;
run;

data _null_;
    set forestModel;
    if prxmatch('m/misclassification/i', description) then
       call symputx('acc_train_forest', (1-value));
run;

title3 'Score the model with ASTORE for the test data';
proc astore;
    score data=heart_disease_test rstore=forstore out=for_scoreout copyvars=(target);
run;

/***********************************
 Compute accuracy score:
 The percentage of patients in test
 data whose predicted heart disease
 status matched their actual status.
 ***********************************/
data _null_;
    retain matchSum 0;
    set for_scoreout(keep=I_target target) end=last;
    match = (I_target = target);
    matchSum + match;
    if last then call symputx ('acc_test_forest', (matchSum/_n_));
run;


/******************************************************************************

 SVMACHINE procedure

 ******************************************************************************/

title2 'Build classification model using PROC SVMACHINE';
ods output FitStatistics=svmstat;
proc svmachine data=heart_disease_train;
    input age--oldpeak / level=interval;
    input ca--fbs / level=nominal;
    target target / level=nominal;
    savestate rstore=svmstore;
run;

data _null_;
    set svmstat;
    if statistic = 'Accuracy' then
       call symputx('acc_train_svmachine', training);
run;

title3 'Score the model with ASTORE for the test data';
proc astore;
    score data=heart_disease_test rstore=svmstore out=svm_scoreout copyvars=(target);
run;

/***********************************
 Compute accuracy score:
 The percentage of patients in test
 data whose predicted heart disease
 status matched their actual status.
 ***********************************/
data _null_;
    retain matchSum 0;
    set svm_scoreout(keep=I_target target) end=last;
    match = (I_target = target);
    matchSum + match;
    if last then call symputx ('acc_test_svmachine', (matchSum/_n_));
run;


/******************************************************************************

 Comparison:
 We have completed the modeling and prediction using 5 different SAS Viya
 procedures for the HEART_DISEASE data set. We also recorded the training
 and test accuracy. In the section below, we will put all the recorded
 accuracy values together and use a bar-chart to display and compare them.

 ******************************************************************************/

%macro CreateComparison;
    %let allprocs = logselect treesplit gradboost forest svmachine;
    data allMethods;
        length procname $16. type $8.;
        %do i = 1 %to %sysfunc(countw(&allprocs));
            %let currentProc = %scan(&allprocs,&i);
            procname = "&currentProc";
            type = "train";
            accuracy = &&&acc_train_&currentProc;
            output;
            procname = "&currentProc";
            type = "test";
            accuracy = &&&acc_test_&currentProc;
            output;
        %end;
    run;
    proc sgplot data=allMethods;
        vbar procname / response=accuracy group=type nostatlabel datalabel
                    groupdisplay=cluster dataskin=pressed;
        xaxis display=(nolabel);
        yaxis grid;
    run;
%mend;

title2 'Compare accuracy across all 5 procedures';
%CreateComparison;

title;