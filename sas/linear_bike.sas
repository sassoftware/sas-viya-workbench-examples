/******************************************************************************

 EXAMPLE:     linear_bike.sas
 DATA:        bike_sharing_demand_train, bike_sharing_demand_test
 DESCRIPTION: This data set contains the hourly and daily count of rental bikes
              with the corresponding weather and seasonal information.
 PURPOSE:     This example shows how to analyze data with visualization tools
              such as SGPLOT and how to fit a regression model to predict bike
              demand using the REGSELECT procedure.

 ******************************************************************************/

title 'Build a regression model to predict bike sharing demand';

/******************************************************************************

 Load the input data.

 ******************************************************************************/

options nosource;
proc import
    datafile="&WORKSPACE_PATH./sas-viya-workbench-examples/data/bike_sharing_demand.csv"
    out=bike_sharing dbms=csv replace;
run;
options source;


/******************************************************************************

 Print a few rows to show the original data.

 ******************************************************************************/

title2 'Original data from bike_sharing_demand_train.csv';
proc print data=bike_sharing (obs=5); run;


/******************************************************************************

 We will use the FORMAT procedure to format the "season", "weather", and
 "workday" columns to make them more readable to users. When calling SAS®
 analytic procedures, the formatted values can also be used instead of the raw
 values.

 ******************************************************************************/

proc format;
    value season
       1='Spring'
       2='Summer'
       3='Fall'
       4='Winter'
    ;
    value weather
       1=" Clear + Few clouds + Partly cloudy + Partly cloudy"
       2=" Mist + Cloudy, Mist + Broken clouds, Mist + Few clouds, Mist "
       3=" Light Snow, Light Rain + Thunderstorm + Scattered clouds, Light Rain + Scattered clouds"
       4=" Heavy Rain + Ice Pallets + Thunderstorm + Mist, Snow + Fog "
    ;
    value workday
       0="non-working days"
       1="working days"
    ;
run;
data bike_sharing;
    set bike_sharing;
    format season season. weather weather. workingday workday.;
run;

title2 'Updated bike_train data with formatted values';
proc print data=bike_sharing (obs=5); run;


/******************************************************************************

 Outliers Analysis
 First, we will use boxplots to visualize how bike demand is distributed
 across different groups and determine the source of the outliers.

 ******************************************************************************/

/******************************************************************************

 First, let's create a simple boxplot for the overall counts in the BIKE_SHARING
 data set. We can observe that all the outliers are in the upper end of the
 overall data. We will use the saved ODS output data set BOXPLOT_OUT for outlier
 removal later.

 ******************************************************************************/

title2 'Boxplot for overall count (demand)';
ods output sgplot=boxplot_out;
proc sgplot data=bike_sharing;
    vbox count;
run;


/******************************************************************************

 Next, we create boxplots for the demand counts for different seasons.
 The plot shows lower demand during Spring but no clear pattern for the outliers.

 ******************************************************************************/

title2 'Boxplot for count (demand) grouped by different seasons';
proc sgplot data=bike_sharing;
    vbox count /category=season;
run;


/******************************************************************************

 We can also create boxplots for the demand counts for different hours
 of the day. We can see the majority of the outliers are between 10am and 3pm.

 ******************************************************************************/

title2 'Boxplot for count (demand) grouped by different hours';
proc sgplot data=bike_sharing;
    vbox count /category=hour;
run;


/******************************************************************************

 Lastly, we create the boxplot for the demand counts against working day versus
 non-working day. We can see clearly that there are more outliers during working
 days than during non-working days.

 ******************************************************************************/

title2 'Boxplot for count (demand): working day vs non-working day';
proc sgplot data=bike_sharing;
    vbox count /category=workingday;
run;


/******************************************************************************

 From BOXPLOT_OUT, we can calculate the Interquartile Range (IQR) value and
 remove any data points larger than Q3 + 1.5*IQR or smaller than Q1 - 1.5*IQR.

 ******************************************************************************/

data _null_;
    set boxplot_out;
    if 'BOX(count)__ST'n eq "Q1" then
        call symputx('q1', 'BOX(count)___Y'n);
    if 'BOX(count)__ST'n eq "Q3" then
        call symputx('q3', 'BOX(count)___Y'n);
run;
%let QTR = %sysevalf(&q3 - &q1);
%let UPPER = %sysevalf(&q3 + 1.5*&QTR);
%let LOWER = %sysevalf(&q1 - 1.5*&QTR);

data bike_sharing;
    set bike_sharing;
    if count > &UPPER or count < &LOWER then delete;
run;


/******************************************************************************

 Correlation Analysis
 A useful way to understand how a dependent variable might be influenced by
 other possible effects in your regression model is to compute the correlation
 between them. Let's also generate a heatmap of the correlation between
 "count" and these effects: "temp", "atemp", "humidity", and "windspeed".

 ******************************************************************************/

/******************************************************************************

 First, we use the CORR procedure to create the correlation matrix.

 ******************************************************************************/

title2 'Correlation between numeric effects';
ods output PearsonCorr=corr;
proc corr data = bike_sharing;
    var count temp atemp humidity windspeed casual registered;
run;


/******************************************************************************

 Sort and transpose the output from the CORR procedure for plotting a heatmap.

 ******************************************************************************/

proc sort data=Corr;
    by variable;
run;
proc transpose data=Corr out=Corr_trans(rename=(COL1=Corr)) name=Correlation;
    var count temp atemp humidity windspeed casual registered;
    by variable;
run;
proc sort data=Corr_trans;
    by variable correlation;
run;


/******************************************************************************

 Use the SGPLOT procedure to produce the heatmap.

 We can sum up what we observe from the heatmap and correlation matrix:
 - "temp" and "humidity" have positive and negative correlation with "count"
   respectively, even though the correlation between them is not very strong.
 - "windspeed" does not have a major impact on "count"
 - "atemp" (feel like temperature) effect should likely not be taken into
   account since "atemp" and "temp" (temperature) have a strong correlation
   with each other, which could produce multicollinearity in the model.
 - "casual" (count of casual users) and "registered" (count of registered users)
   effects are highly correlated with "count". However, they are leakage
   variables directly from "count" and get dropped during model building.

 ******************************************************************************/

title2 'Heatmap of the correlation matrix between count and numeric effects';
proc sgplot data=Corr_trans noautolegend;
    heatmap x=variable y=Correlation / colorresponse=Corr discretex discretey x2axis;
    text x=Variable y=Correlation text=Corr  / textattrs=(size=10pt) x2axis;
    label correlation='Pearson Correlation';
    yaxis reverse display=(nolabel);
    x2axis display=(nolabel);
    gradlegend;
run;


/******************************************************************************

 As shown above, we looked at correlation matrix to understand the basic
 relationship between the dependent variable "count" and the numeric-type effects.
 Let's do the same for the categorical effects: "hour", "weekday", "month", and
 "season".

 ******************************************************************************/

/******************************************************************************

 Distribution of "count" (demand) across different seasons

 ******************************************************************************/

title2 'Count distribution across different seasons';
proc sgplot data=bike_sharing noborder;
   vbar season / response=count stat=mean barwidth=0.8 group=season colorresponse=count;
   xaxis display=(nolabel noline noticks);
   yaxis display=(noline) grid;
   keylegend / noborder;
run;


/******************************************************************************

 Distribution of "count" (demand) across different months

 ******************************************************************************/

title2 'Count distribution across different months';
proc sgplot data=bike_sharing noborder;
   vbar month / response=count stat=mean barwidth=0.8 group=month colorresponse=count;
   xaxis display=(nolabel noline noticks);
   yaxis display=(noline) grid;
   keylegend / noborder;
run;


/******************************************************************************

 Distribution of "count" (demand) across different weekdays

 ******************************************************************************/

title2 'Count (demand) distribution across different weekdays';
proc sgplot data=bike_sharing noborder;
   vbar weekday / response=count stat=mean barwidth=0.8 group=weekday colorresponse=count;
   xaxis display=(nolabel noline noticks);
   yaxis display=(noline) grid;
   keylegend / noborder;
run;


/******************************************************************************

 So far, we do not see any particular patterns except that demand is lower
 during Spring. Instead of creating a distribution for "count" across different
 hours of the day, we will also group the data by weekday (day of the week).

 ******************************************************************************/

title2 'Count (demand) distribution across different hours of the day for
different days of the week';
proc sgplot data=bike_sharing noborder;
   vline hour / response=count stat=mean group=weekday markers;
   xaxis display=(nolabel noline noticks);
   yaxis display=(noline) grid;
   keylegend / noborder;
run;


/******************************************************************************

 The plot from the hourly distribution of "count" grouped by weekday shows
 an interesting pattern. The hourly distribution patterns of every day of the
 week are similar except Saturday and Sunday. We assume this could be due to
 different demand for the bikes between working days and non-working days.
 To show if that is truly the case, we can plot the hourly "count" distribution
 grouped by working day vs non-working day.

 ******************************************************************************/

title2 'Count (demand) distribution across different hours of the day:
working day vs non-working day';
proc sgplot data=bike_sharing noborder;
   vline hour / response=count stat=mean group=workingday markers;
   xaxis display=(nolabel noline noticks);
   yaxis display=(noline) grid;
   keylegend / noborder;
run;


/******************************************************************************

 In fact, the same hourly distributed patterns can also be observed if we plot
 the distribution grouped by casual customers vs registered customers. This is
 likely indicating most of the registered customers use the shared bikes for
 commuting purposes.

 ******************************************************************************/

title2 'Count (demand) distribution across different hours of the day:
casual vs registered customers';
proc sgplot data=bike_sharing noborder;
    vline hour / response=casual stat=mean markers;
    vline hour / response=registered stat=mean markers;
    xaxis display=(nolabel noline noticks);
    yaxis display=(noline) grid;
    keylegend / noborder;
run;


/******************************************************************************

 With more understanding of the data, we are ready to use our analytic tools
 to build a regression model and predict the bike demand.
 We are using the REGSELECT procedure with stepwise model selection to fit a
 regression model for the training data. Among the effects chosen in the final
 model, we see that "count" (demand) is influenced by "temperature" and "month"
 and there appears to be an interaction of "hour" and "weekday".
 Finally, we will predict the demand count for the test data by using the
 ASTORE procedure.

 ******************************************************************************/


/******************************************************************************

 Partition data into training and test sets.
 It is common to split the input data into training data, for training the
 model, and test data, for scoring the model. Here, the PARTITION procedure
 is used to randomly partition BIKE_SHARING into BIKE_TRAIN and
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

 Fit a linear regression model with the REGSELECT procedure.

 ******************************************************************************/

title2 'Fit a regression model with PROC REGSELECT';
proc regselect data=bike_train;
      class hour weekday month season workingday holiday weather;
      model count = hour season weekday month season workingday
            hour*weekday hour*month hour*season hour*workingday
            hour*holiday weather temp windspeed humidity ;
      selection method=stepwise;
      store out=regstore;
run;


/******************************************************************************

 Finally, we predict the bike demand for the test data. The predicted values
 are stored in the variable P_COUNT. We will then plot our predicted demand
 across hour and weekday.

 ******************************************************************************/

title2 'Predict the count (demand) with PROC ASTORE';
proc astore;
   score data=bike_test rstore=regstore out=scoreout copyvars=(_all_);
run;

proc sgplot data=scoreout noborder;
    vline hour / response=p_count stat=mean group=weekday markers;
    xaxis display=(nolabel noline noticks);
    yaxis display=(noline) grid;
    keylegend / noborder;
run;

title;
