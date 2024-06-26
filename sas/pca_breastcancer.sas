/******************************************************************************

 EXAMPLE:     pca_breastcancer.sas
 DATA:        breast_cancer
 DESCRIPTION: The data contains features that are computed from a digitized
              image of a fine needle aspirate (FNA) of a breast mass.
 PURPOSE:     Use the PCA procedure to project the 30-attribute breast cancer
              data into two principal components.

 ******************************************************************************/

title 'Use the PCA procedure to extract principal components for breat cancer data';

/******************************************************************************

 Load the breast_cancer data and show that the data is ready for use.

 ******************************************************************************/

options nosource;
proc import datafile="&WORKSPACE_PATH./sas-viya-workbench-examples/data/breast_cancer.csv"
   out=breast_cancer
   dbms=csv
   replace;
run;
options source;

title2 'Portion of breast_cancer data';
proc print data=breast_cancer(obs=10);
run;

/******************************************************************************

 Use the PCA procedure with N=2 to project the 30-attribute BREAST_CANCER data
 into two principal components. The Proportion column of Eigenvalues table shows
 the Explained Variance Proportion from the two principal components.

 ******************************************************************************/

title2 'Use PCA to extract principal components from breat_cancer data';
proc pca data=breast_cancer n=2 method=nipals;
    output out=pcaout copyvars=(diagnosis);
run;


/*******************************************************************************

 Use the SGPLOT procedure to create a scatter plot that shows the relationship
 between breast cancer diagnosis and the top two principal components.

 Diagnosis group:
 (M) - Malignant
 (B) - Benign

 The output graph from the SGPLOT procedure shows the diagnosis outcome can be
 seen to be separated into two groups by a roughly linear line on the
 2-principal space.

 *******************************************************************************/

title2 'Diagnosis distribution on the 2-principal space';
proc sgplot data=pcaout;
    styleattrs datasymbols=(circlefilled);
    scatter x=score1 y=score2 / group=diagnosis markerattrs=(size=5px);
run;

title;