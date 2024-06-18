/******************************************************************************

 EXAMPLE:     pca_simulated.sas
 DATA:        simulated
 DESCRIPTION: The data is randomly generated with 100000 observations and 100
              variables.
 PURPOSE:     Use the PCA procedure with the RANDOM method to approximate principal
              components and compare with the outcome from EIG method.

 ******************************************************************************/

title 'Use the PCA procedures to approximate principal components for simulated data';

/******************************************************************************

 Generate simulated data with 100000 observations and 100 variables

 ******************************************************************************/

data pca_simulated;
    keep x:;
    drop rank number_of_obs number_of_var sigma ii idum;
    drop rv1 rv2 rsq fac row col;
    drop obs j k;
    array B[50,100];          /* dimensions: rank, number_of_var */
    array A[50];              /* dimension: rank */
    array x[100] x1-x100;     /* dimension: number_of_var */
    rank=50;
    number_of_obs=100000;
    number_of_var=100;
    sigma=0.1;

    call streaminit(1);

    ii = 0;
    idum = 0;
    do while (ii < rank * number_of_var);
        idum = mod(mod(1664525*idum,4294967296)+1013904223,4294967296);
        rv1 = 2.0*(idum/4294967296)-1.0;
        idum = mod(mod(1664525*idum,4294967296)+1013904223,4294967296);
        rv2 = 2.0*(idum/4294967296)-1.0;
        rsq = rv1*rv1+rv2*rv2;
        if ((rsq < 1.0) and (rsq ^= 0.0)) then do;
            fac = sqrt(-2.0*log(rsq)/rsq);
            row = int(ii/number_of_var)+1;
            col = mod(ii,number_of_var)+1;
            B[row,col] = rv1*fac;
            ii = ii + 1;
            if (ii < rank * number_of_var) then do;
                row = int(ii/number_of_var)+1;
                col = mod(ii,number_of_var)+1;
                B[row,col] = rv2*fac;
                ii = ii + 1;
            end;
        end;
    end;

    do obs = 1 to number_of_obs;
        do j = 1 to rank;
            A[j] = rand('Normal');
        end;
        do k = 1 to number_of_var;
            x[k] = sigma*rand('Normal');
            do j = 1 to rank;
                x[k] = x[k] + A[j]*B[j,k];
            end;
        end;
        output;
    end;
run;

/******************************************************************************

 Run the PCA procedure with the RANDOM method for 2 iterations to extract 15
 principal components.

 ******************************************************************************/

title2 'PCA with RANDOM method: 2 iterations';
ods output eigenvalues=twoiter;
proc pca data=pca_simulated n=15 method=random(niter=2);
    var x:;
    display Eigenvalues;
run;


/******************************************************************************

 Run the PCA procedure with the RANDOM method for 10 iterations to
 extract 15 principal components.

 ******************************************************************************/

title2 'PCA with RANDOM method: 10 iterations';
ods output eigenvalues=teniter;
proc pca data=pca_simulated n=15 method=random(niter=10);
    var x:;
    display Eigenvalues;
run;


/******************************************************************************

 Run the PCA procedure again, but with the EIG method to extract 15 principal
 components.

 ******************************************************************************/

title2 'PCA with EIG method';
ods output eigenvalues=trueig;
proc pca data=pca_simulated n=15 method=eig;
    var x:;
    display Eigenvalues;
run;


/******************************************************************************

 Compare the eigenvalues from the 3 PCA procedure calls.

 The result from the run with RANDOM method for 10 iterations is almost
 identical to those from the EIG method.
 The result from the run with RANDOM method for 2 iterations only slightly
 deviates from those from the EIG method.

 ******************************************************************************/
data combine(keep= number two_iter ten_iter true_eig);
    merge twoiter(rename=(eigenvalue=two_iter))
          teniter(rename=(eigenvalue=ten_iter))
          trueig(rename=(eigenvalue=true_eig));
run;

title2 'Eigenvalues from 3 PCA procedure calls';
proc sgplot data=combine(rename=(number=component));
   series x=component y=two_iter /
      legendlabel = 'RANDOM iter=2' markers lineattrs=(color=blue);
   series x=component y=ten_iter /
      legendlabel = 'RANDOM iter=10' markers lineattrs=(color=green);
   series x=component y=true_eig /
      legendlabel = 'True Eigen' markers lineattrs=(color=red);
   yaxis label = 'EigenValue';
run;

title;