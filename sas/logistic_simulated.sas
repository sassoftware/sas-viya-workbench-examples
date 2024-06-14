/******************************************************************************

 EXAMPLE:     logistic_simulated.sas
 DATA:        simulated
 DESCRIPTION: This is a simulated data in shuffled order.
 PURPOSE:     In this example, we showcase a key feature in the LOGSELECT
              procedure: Repeated Measures, which performs a repeated measures
              analysis by using generalized estimating equations (GEEs).

 ******************************************************************************/

 title "Use the LOGSELECT procedure with repeated measures on simulated data";

/******************************************************************************

 Use the data step to generate simulated data.

 ******************************************************************************/

data repeated;
    call streamInit(2021);
    do Subject= 1 to 100;
        do Within =1 to 4;
            Binary=RAND("BINOMIAL",.6,1); /* BINARY */
            X1=RAND('UNIFORM');
            sk=RAND('UNIFORM');
            output;
        end;
    end;
run;


/******************************************************************************

 Use the SORT procedure to scramble the row order  to showcase the
 re-order capability of the repeated measures analysis.

 ******************************************************************************/

proc sort data=repeated;
    by sk;
run;


/******************************************************************************

 Invoke the LOGSELECT procedure with repeated measures to fit the binary
 logistic regression model.

 ******************************************************************************/

title2 'LOGSELECT on simulated data with repeated measures';
proc logselect data=repeated;
    class subject within;
    model binary = x1;
    repeated subject=subject / within=within type=ar(1);
run;

title;
