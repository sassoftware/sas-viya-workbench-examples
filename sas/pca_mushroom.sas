/******************************************************************************
 EXAMPLE:     pca_mushroom.sas
 DATA:        mushroom.csv
 DESCRIPTION: This data set includes descriptions of hypothetical samples
              corresponding to 23 species of gilled mushrooms.
 PURPOSE:     In this example, we will show how to use the PCA procedure to
              reduce model complexity without a loss of accuracy.
 SOURCE:      Adapted from
              "ML_-Decision-Trees-GridSearchCV-PCA-"
              https://github.com/GalaRusina/ML_-Decision-Trees-GridSearchCV-PCA-/tree/main
              Galyna Rusina

 ******************************************************************************/

title 'Reduce model complexity using principal component analysis';

/******************************************************************************

 Load the mushroom data.

 ******************************************************************************/

options nosource;
proc import
    datafile="&WORKSPACE_PATH./sas-viya-workbench-examples/data/mushroom.csv"
    out=mushroom dbms=csv replace;
run;
options source;

proc format;
    value edible_poison
       0="Edible"
       1="Poisonous"
    ;
run;
data mushroom;
    format target edible_poison.;
    set mushroom;
run;

/******************************************************************************

 Print a few rows to show the original data. Use the CONTENTS procedure to
 print more information about the data.

 ******************************************************************************/

title2 'First 5 observations of mushroom data';
proc print data = mushroom (obs=5);
run;

title2 'Information on variable attributes in mushroom data';
ods exclude attributes enginehost;
proc contents data = mushroom;
run;


/******************************************************************************

 All variables comprising the mushroom data set are numberi but are all measured
 on categorical scales. We use the FREQ procedure to see the values and
 corresponding frequencies of each variable. Here, we select just three of the
 variables as examples. Since the veil-type variable has only a single value
 in the data set, we will drop this variable in our modeling later.

 ******************************************************************************/

title2 'Output of the FREQ procedure for target, population and veil_type variables';
proc freq data=mushroom;
   tables target population 'veil-type'n;
run;


/******************************************************************************

 Correlation Analysis
 To better understand how different mushroom characteristics correlate to
 each other and to whether a mushroom is edible or poisonous, we can create a
 correlation matrix and plot the correlation heatmap to visualize it.

 ******************************************************************************/

/******************************************************************************

 First, we use the CORR procedure to create the correlation matrix.

 ******************************************************************************/

title2 'Output from the CORR procedure';
ods output SpearmanCorr=corr;
proc corr data = mushroom spearman;
    var target--habitat;
run;

/******************************************************************************

 Sort and transpose the output from the CORR procedure for plotting a heatmap.

 ******************************************************************************/

proc sort data=Corr;
    by variable;
run;
proc transpose data=Corr out=Corr_trans(rename=(COL1=Corr)) name=Correlation;
    var target--habitat;
    by variable;
run;
proc sort data=Corr_trans;
    by variable correlation;
run;


/******************************************************************************

 Use the SGPLOT procedure to produce the heatmap.

 From the heatmap, we can observe that "gill_size", "spore_print_color" and
 "bruises_" have strong positive correlation to whether a mushroom is poisonous
 or not. We will also drop "veil_type" because it only contains a constant
 value as mentioned previously.

 ******************************************************************************/

title2 'Heatmap of the correlation matrix';
proc sgplot data=Corr_trans noautolegend;
    heatmap x=variable y=Correlation / colorresponse=Corr discretex discretey x2axis;
    label correlation='Pearson Correlation';
    yaxis reverse display=(nolabel);
    x2axis display=(nolabel);
    gradlegend;
run;

data mushroom (drop='veil-type'n);
   set mushroom;
   format target;
run;


/******************************************************************************

 Fit a classification decision tree model for the original mushroom data.

 In this section, we will fit a classification decision tree model and evaluate
 the model by calculating the prediction accuracy. In the later section, we
 use PCA to eliminate less important variables without loss of much accuracy.

 ******************************************************************************/

/******************************************************************************

 First, we partition data into training and test sets.

 It is common to split the input data into training data, for training the
 model, and test data, for scoring the model. Here, the PARTITION procedure is
 used to randomly partition the MUSHROOM data into MUSHROOM_TRAIN and
 MUSHROOM_TEST, with 80% and 20% of the original data, respectively.

 ******************************************************************************/

title2 'Create training and test data sets with the PARTITION procedure';
proc partition data=mushroom seed=12345
    partind samppct=80;
    output out=mushroom_part;
run;

data mushroom_train(drop=_partind_);
    set mushroom_part(where=(_partind_=1));
run;

data mushroom_test(drop=_partind_);
    set mushroom_part(where=(_partind_~=1));
run;

/******************************************************************************

 Next, we use the TREESPLIT procedure to fit a classification decision tree
 model. We will collect the classification accuracy for both training and
 test data.

 ******************************************************************************/

title2 'Build classification model using PROC TREESPLIT';
ods output treeperformance=treestat;
proc treesplit data=mushroom_train;
    class target 'cap-shape'n--habitat;
    model target = 'cap-shape'n--habitat;
    prune c45;
    savestate rstore=dtstore;
run;

data _null_;
    set treestat;
    call symputx('accuracy_train_original', (1-MiscRate));
run;

title3 'Score the model with ASTORE for the test data';
proc astore;
    score data=mushroom_test rstore=dtstore out=dt_scoreout copyvars=(target);
run;

/***********************************
 Compute accuracy score:
 The percentage of mushrooms correctly
 identified in the prediction.
 ***********************************/
data _null_;
    retain matchSum 0;
    set dt_scoreout(keep=I_target target) end=last;
    match = (I_target = target);
    matchSum + match;
    if last then call symputx ('accuracy_test_original', (matchSum/_n_));
run;


/******************************************************************************

 Use PCA to reduce the model complexity.

 PCA (Principal Components Analysis) is a multivariate technique for examining
 relationships among several quantitative variables. It provides an optimal way
 to reduce dimensionality by projecting the data onto a lower-dimensional
 orthogonal subspace that explains as much variation as possible in those
 variables. We will show how to use this technique to reduce the number of
 variables in our model.

 ******************************************************************************/

/******************************************************************************

 Use the scree plots from the PCA procedure to visualize the explainability
 as the number of principal components increases.
 From the "Variance Explained" plot, we can see the first 15 components account
 for about 95% of the total variance.

 ******************************************************************************/

ods graphics on;
title2 'PCA procedure with scree plots';
proc pca data=mushroom method=nipals plots;
run;


/******************************************************************************

 Another useful visualization tool provided by the PCA procedure is the
 pairwise component pattern plots. These plots can show us how the variables
 correlate with the principal components. For demonstration purpose, we select
 only the top 3 principal components.

 ******************************************************************************/

title2 'PCA procedure with pairwise component pattern plots';
proc pca data=mushroom method=nipals plots=(pattern(ncomp=3));
run;


/******************************************************************************

 Now, we can use the PCA procedure to transform the mushroom data into a
 15-dimensional data set. We will fit a classification decision tree model
 for the transformed data and compare the accuracy with the one from the
 original data.

 ******************************************************************************/

title2 'Use PCA to project mushroom data into 15-dimensional data';
proc pca data=mushroom method=nipals n=15;
    output out=mushroom_pca copyvars=(target);
run;


/******************************************************************************

 Partition the transformed mushroom data into training (80%) and test (20%)
 data sets.

 ******************************************************************************/

title2 'Create training and test data sets with the PARTITION procedure';
proc partition data=mushroom_pca seed=12345
    partind samppct=80;
    output out=mushroom_pca_part;
run;

data mushroom_pca_train(drop=_partind_);
    set mushroom_pca_part(where=(_partind_=1));
run;

data mushroom_pca_test(drop=_partind_);
    set mushroom_pca_part(where=(_partind_~=1));
run;


/******************************************************************************

 Use the TREESPLIT procedure again to fit a classification decision tree
 model for the transformed data.

 ******************************************************************************/

title2 'Build classification model using PROC TREESPLIT';
ods output treeperformance=treestat2;
proc treesplit data=mushroom_pca_train;
    class target;
    model target = score1--score15;
    prune c45;
    savestate rstore=dtstore2;
run;

data _null_;
    set treestat2;
    call symputx('accuracy_train_pca', (1-MiscRate));
run;

title3 'Score the model with ASTORE for the test data';
proc astore;
    score data=mushroom_pca_test rstore=dtstore2 out=dt_scoreout2 copyvars=(target);
run;

/***********************************
 Compute accuracy score:
 The percentage of mushrooms correctly
 identified in the prediction.
 ***********************************/
data _null_;
    retain matchSum 0;
    set dt_scoreout2(keep=I_target target) end=last;
    match = (I_target = target);
    matchSum + match;
    if last then call symputx ('accuracy_test_pca', (matchSum/_n_));
run;


/******************************************************************************

 Lastly, we compare the accuracy results from the original data and the
 transformed data. We can see that with the reduction of dimensionality from
 23 to 15, the accuracy does not drop significantly.

 ******************************************************************************/

data comparison;
    length data $16. type $8.;
    data = "Original";
    type = "train";
    accuracy = &accuracy_train_original;
    output;
    procname = "Original";
    type = "test";
    accuracy = &accuracy_test_original;
    output;
    data = "PCA transformed";
    type = "train";
    accuracy = &accuracy_train_pca;
    output;
    procname = "PCA transformed";
    type = "test";
    accuracy = &accuracy_test_pca;
    output;
run;

title2 'Comparison of accuracy values: original data vs transformed data';
proc sgplot data=comparison;
    vbar data / response=accuracy group=type nostatlabel datalabel
                groupdisplay=cluster dataskin=pressed;
    xaxis display=(nolabel);
    yaxis grid;
run;

title;