/* libname to have persistent data */
LIBNAME project '/home/u63838773';


/* XLSX import */
FILENAME REFFILE '/home/u63838773/Project/Emigration.xlsx';
PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=project.emigration;
	GETNAMES=YES;
RUN;
PROC CONTENTS DATA=project.emigration; RUN;


FILENAME REFFILE '/home/u63838773/Project/Quality_of_Life_Indicators.xlsx';
PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=project.quality_indicators;
	GETNAMES=YES;
RUN;
PROC CONTENTS DATA=project.quality_indicators; RUN;


FILENAME REFFILE '/home/u63838773/Project/Offences.xlsx';
PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=project.offences;
	GETNAMES=YES;
RUN;
PROC CONTENTS DATA=project.offences; RUN;


/* change Money_laundering and Sexual_exploitation to numeric */
DATA project.offences;
    SET project.offences;
    Money_laundering_num = INPUT(Money_laundering, ??32.);
    Sexual_exploitation_num = INPUT(Sexual_exploitation, ??32.);
DROP Money_laundering Sexual_exploitation;
RUN;

/* add all the offences */
DATA project.total_offences;
  SET project.offences;
  Offences = SUM(of _numeric_);
  KEEP Country Offences;
RUN;

/* display total offences */
PROC PRINT DATA = project.total_offences noobs;
	TITLE 'Total offences';
RUN;

/* merge the data sets into data_set with a match-merge */
/*
In the next example, the program match-merges the three data sets and uses the IN= data set option on the input data sets to remove the unmatched observations from the output data set.
The IN= data set option is a Boolean value variable, which has a value of 1 if the data set contributes to the current observation in the output and a value of 0 if the data set does not contribute to the current observation in the output.
*/
PROC SORT DATA=project.emigration; BY Country; RUN;
PROC SORT DATA=project.quality_indicators; BY Country; RUN;
PROC SORT DATA=project.total_offences; BY Country; RUN;

/* merge based on one-to-one correspondence */
/* DATA project.data_set; */
/*    MERGE project.emigration(IN=i) project.quality_indicators(IN=j) project.total_offences(IN=k); */
/*    BY Country; */
/*    IF (i=1) AND (j=1) AND (k=1); */
/* RUN; */

/* merge based on one-to-one correspondence */
DATA project.data_set;                       	
MERGE project.emigration project.quality_indicators;
BY Country;

/* INNER JOIN using SQL */
PROC SQL;
Create table project.data_set as
Select * from project.data_set as ds, project.total_offences as to
where ds.Country = to.Country;
QUIT;

PROC PRINT DATA = project.data_set noobs;
   TITLE 'Final data set';
RUN;

/* rename variables */
DATA project.data_set;
    SET project.data_set(RENAME=(Average_Income = AvgIncome 
    At_risk_of_poverty_rate = PovRate 
    Main_GDP_aggregates_per_capita = GDP 
    Severe_material_deprivation_rate = SVDRate 
    Overcrowding_rate = OcwRate 
    Unemployment_rates = UnpRate 
    Life_expectancy = LifeExp 
    Unmet_medical_needs = UMN 
    Early_leavers_from_education = EarlyLeavers  
    Arrears = Debtors 
    Gender_employment_gap = GEmpGap 
    Pollution_grime_or_other_environ = PGEP 
    ));
RUN;

PROC PRINT DATA = project.data_set noobs;
   TITLE 'Data set with renamed variables';
RUN;

/* remove leading, between and trailing spaces in Country column */
DATA project.data_set;
SET project.data_set;
Country = compress(Country);
RUN;

/* by making a new data set, display the emigrants from countries that have lower income and high unemployment rate */
/* save and display average of Average Income using PROC MEANS */
PROC MEANS DATA=project.data_set MEAN noprint;
  VAR AvgIncome;
  OUTPUT OUT=project.averages MEAN=Average;
PROC PRINT DATA=project.averages noobs;
  VAR Average;
RUN;
/* save and display average of Unemployment Rate using PROC MEANS */
PROC MEANS DATA=project.data_set MEAN noprint;
  VAR UnpRate;
  OUTPUT OUT=project.averages MEAN=Average;
PROC PRINT DATA=project.averages noobs;
  VAR Average;
RUN;
/* save and display subset */
DATA income_unemployment;
    SET project.data_set;
	IF AvgIncome <= 17567.1 & UnpRate > 6.8;
RUN;
TITLE 'Emigrants from countries that have lower income and high unemployment rate';
PROC PRINT DATA=income_unemployment noobs;
RUN;

/* grouping countries by income */
DATA income;
SET project.data_set;
	SELECT;
		WHEN (missing(AvgIncome)) Group = . ;
		WHEN (AvgIncome le 16567.1) Group = 1;
		WHEN (AvgIncome gt 18567.1) Group = 2;
		OTHERWISE Group = 3;
	END;
TITLE 'Countries grouped by income';
FOOTNOTE1 'Group 1 - significantly lower than average';
FOOTNOTE2 'Group 2 - significantly higher than average';
FOOTNOTE3 'Group 3 - around average';
KEEP Country AvgIncome Group;
PROC PRINT DATA=income;
RUN;

/* generating aggregated reports with MEANS procedure */
PROC MEANS DATA = project.data_set;
   VAR Emigrants;
   TITLE 'Emigrants report';
RUN;

/* create a format for emigrants ranges */
PROC FORMAT;
  VALUE EmgFmt 
    low-10000 = 'Up to 10,000'
    10000-50000 = '10,000 - 50,000'
    50000-200000 = '50,000 - 200,000'
    200000-500000 = '200,000 - 500,000'
    550000-high = 'Over 550,000';
RUN;
/* categorize emigrants using the format */
DATA emg_data;
  SET project.data_set;
  Category = PUT(Emigrants, EmgFmt.);
  KEEP Country Emigrants Category;
RUN;
/* display them sorted */
PROC SORT DATA=emg_data;
   BY Emigrants;
RUN;
PROC PRINT DATA=emg_data noobs;
RUN;

/* generate 2 subsets (low and high emigrants) in order to compare them with Romania */
/* low emigrants */
DATA project.subset1;
   SET project.data_set;
   IF Emigrants = 3384.00;
   DROP Country;
RUN;
/* save the variables related to Romania in a subset */
DATA project.subset2;
   SET project.data_set;
   IF Country = 'Romania';
   DROP Country;
RUN;
/* high emigrants */
DATA project.subset3;
   SET project.data_set;
   IF Emigrants = 576319.00;
   DROP Country;
RUN;

PROC PRINT DATA=project.subset1 noobs;
TITLE 'Emigrants and quality of life indicators in Slovakia';
PROC PRINT DATA=project.subset2 noobs;
TITLE 'Emigrants and quality of life indicators in Romania';
PROC PRINT DATA=project.subset3 noobs;
TITLE 'Emigrants and quality of life indicators in Germany';
RUN;


/* user-defined format to display emigrants from countries based on average emigrants */
/* save average of emigrants using PROC MEANS */
PROC MEANS DATA=project.data_set mean noprint;
  VAR Emigrants;
  OUTPUT OUT=project.averages MEAN=Average;
RUN;
/* display the average */
PROC PRINT DATA=project.averages noobs;
  VAR Average;
RUN;
/*create the user-defined format */
PROC FORMAT;
VALUE EmigrantsFmt
 low - 94639 = 'Low'
 94639 - high = 'High'
 other = 'Missing';
RUN;
/* display the data from Emigration data set with the format by making a subset */
DATA project.subset_emigrants;
    SET project.data_set;
    KEEP Country Emigrants;
RUN;

PROC PRINT DATA=project.subset_emigrants noobs;
TITLE 'Emigrants throughout Europe';
FORMAT Emigrants EmigrantsFmt.;
RUN;

/* determine how many countries have low or high unmet medical needs, using the procedure of calculating the occurrence frequencies and 
a user-defined format. */
/* save average of UMN using PROC MEANS */
PROC MEANS DATA=project.data_set mean noprint;
  VAR UMN;
  OUTPUT OUT=project.averages MEAN=Average;
RUN;
/* display the average */
PROC PRINT DATA=project.averages noobs;
  VAR Average;
RUN;
/* define a user-defined format to categorize unmet medical needs */
PROC FORMAT;
  VALUE MedicalNeedsFmt
    low - 2.8 = 'Low'
    2.8 - high = 'High';
RUN;
/* calculate occurrence frequencies using PROC FREQ */
proc freq DATA=project.data_set;
  FORMAT UMN MedicalNeedsFmt.;
  tables UMN / nocum nopercent;
  TITLE 'No. of countries with low or high unmet medical needs';
RUN;

/* display poverty rates throughout Europe in a star chart */
TITLE 'Poverty rates in Europe';
PROC GCHART DATA=project.data_set;
   star Country / sumvar=PovRate;
RUN;
QUIT;

/* display emigrants in a histogram along with descriptive statistics by using univariate */
PROC UNIVARIATE DATA=project.data_set NEXTROBS = 0;
	VAR Emigrants;
	HISTOGRAM Emigrants;
	Title "Statistical data for emigrants throughout Europe";
RUN;

/* display emigrants in Europe by using a scatter plot with dots */
SYMBOL value=dot;
TITLE 'Emigrants throughout Europe';
 PROC GPLOT DATA=project.data_set;
 	PLOT Country * Emigrants;
RUN;
QUIT;

/* display countries with their emigrants and offences by using a text plot */
TITLE 'Emigrants and Offences';
PROC SGPLOT DATA=project.data_set;
 TEXT x=Offences y=Emigrants text=Country / 
  outline backfill;
RUN;
QUIT;

/* correlation between all the variables - Pearson's correlation coefficient by default */
PROC CORR DATA = project.data_set;
RUN;

/* correlation between emigrants and highly correlated variables to emphasize their correlation */
PROC CORR DATA = project.data_set;
   VAR EarlyLeavers GEmpGap PGEP Offences;
   WITH Emigrants;
   TITLE1 'Correlation between emigrants';
   TITLE2 'and early leavers, gender employment gap, pollution or offences ';
RUN;

/* MLR */
/* how are emigrants impacted by EarlyLeavers GEmpGap PGEP Offences */
PROC REG DATA = project.data_set;
  MODEL Emigrants = EarlyLeavers GEmpGap PGEP Offences;
RUN;