/*
26777 Data Processing Using SAS
Autumn 2022
Data analysis and reporting- Assessment 2


Student Name- Kushal Ahuja
Student ID Number- 14191922

*/

ods pdf file=


libname practice "/home/u61015946/Kushal_Personal/Assignment";

proc import datafile="/home/u61015946/Kushal_Personal/Assignment/keywords.csv" 
		dbms=csv out=practice.keywords replace;
run;

proc import 
		datafile="/home/u61015946/Kushal_Personal/Assignment/metadata-easier.csv" 
		dbms=csv out=practice.metadata replace;
	guessingrows=500;
run;

proc sort data=practice.metadata out=practice.metadata_sorted;
	by id;
run;

data metadata_keywords;
	merge practice.metadata_sorted practice.keywords;
	by id;
run;

*removing duplicates;

proc sort data=metadata_keywords nodupkey;
	by id;
run;

/* Checking the contents of the dataset */
proc contents data=practice.metadata;
Title 'Contents of the Metadata';
run;

proc contents data=practice.keywords;
Title 'Contents of the Keywords';
run;

/* 1*/
data review;
	set metadata_keywords;
	keep original_title release_date vote_average;
	where release_date is not missing;
run;

title Average Review;
proc means data=review;
	var vote_average;
	label vote_average= "Vote Average";
run;


proc sort data=review;
	by descending release_date;
run;
/*Change in average review over time*/ 

ods noproctitle;
Title Average Review;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.REVIEW;
	title height=14pt "Ratings Of Movies Throughout The Years";
	scatter x=vote_average y=release_date /;
	xaxis grid;
	yaxis grid;
run;

ods graphics / reset;
title;


/*Which genre are popular */

data genre;
	set metadata_keywords;
	keep genres popularity release_date;
	where genres is not missing;
run;


*pie chart;

proc template;
	define statgraph SASStudio.Pie;
	title height=14pt "Distribution of the popularity among genre";
		begingraph;
		layout region;
		piechart category=genres / stat=pct datalabellocation=inside;
		endlayout;
		endgraph;
	end;
run;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgrender template=SASStudio.Pie data=WORK.GENRE;
run;

ods graphics / reset;

/*What genres are popular? Has this changed over time*/

data populargenre;
	set metadata_keywords;
	keep popularity genres;
run;

proc sort data=populargenre;
	by descending popularity;
	where genres is not missing;
run;

proc freq data=populargenre order=freq;
	tables genres / noprint nocum out=list_values;
run;

ods noproctitle;
title Popular genres;
proc print data=list_values (obs=20);
	where genres is not missing;
run;

*To know the change in popularity of drama;

data drama_genre;
	set metadata_keywords;
	where genres contains 'Drama';
run;

/*
how the popularity of drama genre has changed over time
*/
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sort data=WORK.DRAMA_GENRE out=_SeriesPlotTaskData;
	by release_date;
run;

proc sgplot data=_SeriesPlotTaskData;
	title height=14pt "Popularity of drama genre over time";
	series x=release_date y=popularity /;
	xaxis grid;
	yaxis grid;
run;

ods graphics / reset;

proc datasets library=WORK noprint;
	delete _SeriesPlotTaskData;
	run;



*top50 vote count and common keywords;

proc sort data=metadata_keywords;
	by descending keywords vote_count;
run;

title top8 vote count and common keywords;
proc print data=metadata_keywords (obs=8);
	var vote_count keywords;
	where vote_count > 10000;
run;

/*Does production budget relate to popularity?*/

data correlation;
	set metadata_keywords;
	keep budget popularity;
	where budget is not missing;
	where popularity is not missing;
	label 
	budget="Budget"
	popularity="Popularity";
run;
ods noproctitle;
title Relation between Production budget and Popularity;
proc corr data=metadata_keywords;
	var budget popularity;
	where budget is not missing;
	where popularity is not missing;
run;

/*
Correlation Plot
*/
ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.CORRELATION;
	title height=14pt "Correlation between Production Budget and Popularity";
	footnote2 justify=left height=10pt 
		"Pearson Correlation Value 0.45053 (Positive Weak Correlation) P-value:<.0001";
	reg x=budget y=popularity / nomarkers;
	scatter x=budget y=popularity /;
	xaxis grid;
	yaxis grid;
run;

ods graphics / reset;
title;
footnote2;

/*conditional processing of runtime containing changing the variable type*/
data movie_runtime;
	set metadata_keywords;
	length runtime_new $20;
	length Duration $10;
	runtime_new=input (runtime, ??10.1);
	format runtime 30.0;
	where runtime is not missing and title is not missing;
	
	if runtime_new < 90 then
		Duration='Short';
	else if runtime_new > 120 then
		Duration='Medium';
	else
		Duration='Long';
run;

title Duration of movies; 

proc print data=movie_runtime (obs=30);
	var title Duration runtime_new;
run;

/* Conditional processing for classifying the movie revenue*/
data revenue_new;
	set metadata_keywords;
	length Gross $20;
	format revenue dollar30.;
	where title is not missing and revenue is not missing and revenue ~=0;

	if revenue < 50000000 then
		Gross='Good';
	else if revenue > 50000000 and revenue < 100000000 then
		Gross='Blockbuster';
	else
		Gross='Top Grossing ';
run;

title Gross Revenue of Movies;
proc print data=revenue_new (obs=20);
	var id title Gross;
run;


*Analysis by using proc univariate;

ods noproctitle;
title1 "Budget Analysis";
proc univariate data=metadata_keywords;
	var budget;
	where budget is not missing;

output out= maximum_budget
max= budget;
run;

proc print data = maximum_budget;
run;



*Classifying the vote count in character format by Custom formatting for easy understanding;

proc format;
	value vote_average low -<400 = "small"
						 400- <900 = "medium"
						 900- high = "large"
						 ;
run; 

data vote_format;
	set metadata_keywords;
	format  vote_count vote_average.;
	
	keep title vote_count ;
run;

title Vote Count classification;
proc print data=vote_format (obs=30);
run;

title Vote Count classification;
proc print  data=vote_format(obs=30);
	format vote_count ;
	run;
	
	
*Evluating if the movie sequels are good as the orignal ones by analysing ratings of Toy Story;

	data toy_story;
set metadata_keywords;
where title contains 'Toy Story';
keep title  popularity release_date ;
run;



/* Compute axis ranges */
proc means data=WORK.TOY_STORY noprint;
	class title / order=data;
	var popularity release_date;
	output out=_BarLine_(where=(_type_ > 0)) sum(popularity release_date)=resp1 
		resp2;
run;

/* Compute response min and max values (include 0 in computations) */
data _null_;
	retain respmin 0 respmax 0;
	retain respmin1 0 respmax1 0 respmin2 0 respmax2 0;
	set _BarLine_ end=last;
	respmin1=min(respmin1, resp1);
	respmin2=min(respmin2, resp2);
	respmax1=max(respmax1, resp1);
	respmax2=max(respmax2, resp2);

	if last then
		do;
			call symputx ("respmin1", respmin1);
			call symputx ("respmax1", respmax1);
			call symputx ("respmin2", respmin2);
			call symputx ("respmax2", respmax2);
			call symputx ("respmin", min(respmin1, respmin2));
			call symputx ("respmax", max(respmax1, respmax2));
		end;
run;

/* macro for offset */
%macro offset ();
	%if %sysevalf(&respmin eq 0) %then
		%do;
			offsetmin=0 %end;

	%if %sysevalf(&respmax eq 0) %then
		%do;
			offsetmax=0 %end;
%mend offset;

ods graphics / reset width=6.4in height=4.8in imagemap;

proc sgplot data=WORK.TOY_STORY nocycleattrs;
	title height=14pt "Ratings of Toy Story sequels get lower";
	footnote2 justify=left height=12pt "The line denotes the release date";
	vbar title / response=popularity datalabel fillattrs=(color=CXd7d1e4) stat=sum;
	vline title / response=release_date datalabel stat=sum y2axis;
	yaxis grid min=&respmin1 max=&respmax1 %offset();
	y2axis min=&respmin2 max=&respmax2 %offset();
	keylegend / location=outside;
run;

ods graphics / reset;
title;
footnote2;

proc datasets library=WORK noprint;
	delete _BarLine_;
	run;
	
	
*Using Macro;
	
	data thriller_genre;
	set metadata_keywords;
	keep genres popularity;
	where genres contains "Thriller";
	run;
	
%let genre_group = Thriller;
title Thriller Genre Movies Popularity;

proc print data=thriller_genre (obs=10);
	where genres="&genre_group";
run;

*Use of funtions to see the  vote;


data data total_vote;
set metadata_keywords;
Totalvote= sum (vote_count * vote_average);
run;

title Votes for movies;
proc print data=total_vote (obs=10);
var totalvote vote_count vote_average title;
run;












