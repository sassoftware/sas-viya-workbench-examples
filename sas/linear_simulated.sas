/******************************************************************************

 EXAMPLE:     linear_simulated.sas
 DATA:        simulated
 DESCRIPTION: This is a simulated data with 500k rows of randomly generated
              observations.
 PURPOSE:     In this example, we define a macro and use the data step to simulate
              data. This allows us to generate data over various sizes and
              structure to test the regression functionality.

 ******************************************************************************/

 title 'Run the REGSELECT procedure with simulated data';

/******************************************************************************

 Define the macro function that generates simulated data.

 ******************************************************************************/

%macro makeRegressorData(nBy=1,nByFixedSize=1,nObs=100,nCont=4,
                         nClass=3,nLev1=3,nLev2=5,nLev3=7);
    data regressors;
        drop i j;
        %if &nCont>0  %then %do;
            array x{&nCont}  x1-x&nCont;
        %end;
        %if &nClass>0 %then %do;
            array c{&nClass} c1-c&nClass;
        %end;

        do by1=1 to &nBy;
            if by1 > &nByFixedSize then
                nObsInBy = floor(2*ranuni(1)*&nObs);
            else
                nObsInBy = &nObs;
            if nObsInBy < 10 then
                nObsInBy = 10;

            do i = 1 to nObsInBy;
                %if &nCont>0 %then %do;
                    do j= 1 to &nCont;
                        x{j} = ranuni(1);
                    end;
                %end;
                %if &nClass > 0 %then %do;
                    do j=1 to &nClass;
                        if mod(j,3) = 0 then
                            c{j} = ranbin(1,&nLev3,.6);
                        else if mod(j,3) = 1 then
                            c{j} = ranbin(1,&nLev1,.5);
                        else if mod(j,3) = 2 then
                            c{j} = ranbin(1,&nLev2,.4);
                    end;
                %end;
                weight = 1 + ranuni(1);
                freq   = 1 + mod(i,3);
                y = rannor(1);
                output;
            end;
        end;
    run;
%mend;

/******************************************************************************

 Generate the simulated data with 500k observations and the following variables:
 y - response
 x1 - continuous variable
 c1 - classification variable

 ******************************************************************************/

%makeRegressorData(nBy=1,nByFixedSize=1,nObs=500000,nCont=1,
                         nClass=1,nLev1=2,nLev2=3,nLev3=4);


/******************************************************************************

 Call the REGSELECT procedure without the need of a separate cloud-based server
 on the simulated problem and create the astore file for scoring later.

 ******************************************************************************/

title2 'REGSELECT on simulated data';
proc regselect data=regressors;
      class c1;
      model y =x1 c1 x1*c1;
      store out=regstore;
run;


/******************************************************************************

 Describing the astore gives us information about the model. We then use it
 to score the data and save the result in the SCOREOUT data set.
 A sample of the results are printed.

******************************************************************************/

title2 'ASTORE describe and scoring';
proc astore;
   describe rstore=regstore;
   score data=regressors rstore=regstore out=scoreout;
run;

proc print data=scoreout(obs=5);
run;



/******************************************************************************

 Astores can be saved as files for use in subsequent programs or entirely
 different environments.

 ******************************************************************************/

title2 'Saving the astore into a file';
proc astore;
    download rstore=regstore store="/tmp/regstore.sasast";
run;


/******************************************************************************

 To replicate this, we will reload it under a new name, describe it to see that
 nothing has changed, and then score the data against it again.

 ******************************************************************************/

title2 'Reloading the astore and scoring it';
proc astore;
    upload rstore=regstore2 store="/tmp/regstore.sasast";
    describe rstore=regstore2;
    score data=regressors rstore=regstore2 out=scoreout2;
run;

proc print data=scoreout2(obs=5);
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