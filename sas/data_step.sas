/******************************************************************************

 EXAMPLE:     data_step.sas
 DATA:        bonus
 DESCRIPTION: This is a simple data set that contains bonuses for
              different position titles at a hypothetical company.
 PURPOSE:     In this example, we will demonstrate a few different ways of
              using the SAS® Data Step to read and process data.

 ******************************************************************************/

title 'Examples of using SAS Data Step';

/******************************************************************************

 Read an external file

 In most of the other SAS examples in SAS® Viya® Workbench, we show how to use the
 IMPORT procedure to import data from external file sources such as CSV files.
 In the example below, we show how to use the data step to create a SAS data
 set from a CSV file.

 ******************************************************************************/

data bonus;
    infile "&WORKSPACE_PATH./sas-viya-workbench-examples/data/bonus.csv" dsd firstobs=2;
    length title $24;
    input title $ jobcode bonus;
run;


/******************************************************************************

 A few points about the example above:

 - The INFILE statement allows users to specify an external file source.
 - The DSD option (delimiter-sensitive data) reads the delimited CSV file.
 - The file contains a header row with data starting in the second row.
 - As a result, we add option FIRSTOBS=2 to skip the header row.
 - Since "title" is a character variable, we need to specify the length to avoid
   truncation issues due to the default length being determined by the value in
   the first observation.

 ******************************************************************************/

title2 'Bonus data from bonus.csv';
proc print data=bonus;
run;


/******************************************************************************

 Instead of creating data from an external file, we can also use the data step
 to create data directly. We will use the DATALINES statement to show how to
 create a data set containing the first name of 5 employees and their jobcode.

 ******************************************************************************/

data employees;
    input name :$8. jobcode;
datalines;
Arthur 3
Bob    1
Carol  5
David  3
Edison 7
;


title2 'Employees data created by DATALINES';
proc print data=employees;
run;


/******************************************************************************

 Assuming the EMPLOYEES and the BONUS data sets are both from the same
 company, we can combine the information of the two data sets into a single
 data set.

 We will use variable "jobcode" as our key to match the two data sets because
 "jobcode" is the only common variable in two data sets.

 ******************************************************************************/

/******************************************************************************

 Before matching data, both data sets need to be sorted by the key variable.

 ******************************************************************************/

proc sort data=bonus;
    by jobcode;
run;
proc sort data=employees;
    by jobcode;
run;


/******************************************************************************

 We now merge the two data by matching the "jobcode" variable. The EMPLOYEES
 data set does not include all job codes found in BONUS. If we do not want
 records in the combined data with missing values for employees, we can
 use the IN= data set option to include only the records with employees present
 in the EMPLOYEES data set.

 ******************************************************************************/

data employees_bonus;
    merge employees(in=in_employees) bonus;
    by jobcode;
    if in_employees;
run;

title2 'Merged data from employees and bonus';
proc print data=employees_bonus;
run;


/******************************************************************************

 We can also use another tool, the SQL procedure, to create the same merged
 data by using left join operation.

 ******************************************************************************/

proc sql;
    create table employees_bonus2 as
    select employees.*, bonus from employees as emp left join bonus as bon
    on emp.jobcode = bon.jobcode;
quit;

title2 'Merged data from employees and bonus by PROC SQL';
proc print data=employees_bonus2;
run;


/******************************************************************************

 Now, if we do not want to display the exact bonus of each employee but
 instead display the range of bonus, we can define a custom format and apply
 the format to variable "bonus".

 ******************************************************************************/

proc format;
    value bonus
    low - <3000   = "Lower than 3,000"
    3000 - <5000 = "Between 3,000 and 5,000"
    5000 - high   = "Over 5,000"
    ;
run;

data employees_bonus;
    set employees_bonus;
    format bonus bonus.;
run;

title2 'Merged data with formatted bonus';
proc print data=employees_bonus;
run;


/******************************************************************************

 So far, we have shown how to read an external file into the data step and
 how to input data directly into Data Step via the DATALINES statement. In
 the example below, we will show how to create data programmatically through
 the DO LOOP in the data step.

 ******************************************************************************/

data circle;
    do theta = 0 to 6.28 by 0.01;
        x = cos(theta);
        y = sin(theta);
        output;
    end;
run;


/******************************************************************************

 We can use the SGPLOT procedure to visualize the data created in this Data Step.

 ******************************************************************************/

title2 'Use DO-LOOP to create circle data';
proc sgplot data=circle;
    series x=x y=y;
run;

title;