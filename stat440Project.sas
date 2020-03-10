

data player;
length birthD $24 birth $24 college $36 high $36 team $24 name $24 pos $ 70 round $20 playerid $ 16;
infile "/home/u43003517/stat_440/players (2).csv" dsd dlm= "," truncover firstobs= 2;
input playerid $ birthD $ birth $ assist FG FG3 FT G PER PTS TRB WS eFG college $ pick $ round $ team $ year height $ high $ name $ pos $ shoot $ weight $;
if pos = " " then delete;
format pos $posfmt. ;
run; 

proc sort data= player out = sort_player;
by playerid;

data salaries;
length playerid $16;
infile "/home/u43003517/stat_440/salaries_1985to2018.csv" dlm= "," truncover firstobs= 2;
input league $ playerid $  salary  season $7.  end start team $24. ;
format salary comma12.;
run;



 proc sort data= salaries out = sort_salary;
 	by playerid;
data salary_new;
	set sort_salary;
	by playerid;
	if First.playerid then do; 
	playersal = 0;
	Num = 0;
	end;
	playersal + salary;
	Num + 1;
	if last.playerid;
	avg = playersal/ Num;
	label playerid = "Player ID"
		avg = 'Average Player Salary'
		playersal = 'Total Player Salary'
		Num = "Number of Seasons Played"
		start = "Season Start"
		end = "Season End";
	format salary comma12. playersal comma12. avg comma12. ;
run;
	


data player_new;
 	 set sort_player;
 	where year >= 1985 and year <= 2018 ;
 
data salary_new;
	set salary_new;
	where start >= 1985 and start <= 2018;
proc sort data = salary_new out= salary_new;
	by playerid;
proc sort data= player_new out= player_new;
	by playerid;

data data_merged;
	merge salary_new player_new;
	by playerid;
	keep playerid salary team playersal avg pos WS;
run;



proc sort data= data_merged out= team_sort;
by team;

data team_sal;
	set team_sort;
	by team;
	if First.team then do;
	team_total = 0;
	Number = 0;
	end;
	team_total + avg;
	Number + 1;
	if Last.team;
	team_avg_sal = team_total/Number;
	label playerid = 'Player ID'
		  pos = 'Position'
		  team_avg_sal = 'Average Team Salary per Player'
		  Number = 'Total number of players';
	format team_avg_sal comma12.;
	keep team_avg_sal team Number;
proc sort data= team_sal out = team_sal_sort;
by descending team_avg_sal;

/* Extreme values */
proc univariate data= team_sal;
var team_avg_sal;


/* max and min values */
proc print data= team_sal (firstobs= 22 obs=22) noobs label;
/* maximum value */
proc print data= team_sal (firstobs= 21 obs=21) noobs label;
/* teams between the 1st and third quartiles*/
proc print data= team_sal label noobs;
where team_avg_sal <= 2165926 and team_avg_sal <= 1645882;
/* top 10% */
proc print data= team_sal label noobs;
where team_avg_sal >=2859725;




proc sort data= data_merged out = Ws_team;
by team;

/* average player win share for team */
data team_win_share;
	set Ws_team;
	by team;
	if first.team then do;
		total_ws = 0;
		Num = 0;
	end;
	total_ws + WS;
	Num + 1;
	if last.team;
	avg_ws = total_ws / Num;
	keep team avg_ws;
	label avg_ws = 'Average Player Win Share for Team';
proc sort data= team_win_share out = team_win_share_sort;
by descending avg_ws;


data ws_and_salary;
merge team_sal team_win_share;
by team;
keep team team_avg_sal avg_ws;
label team_avg_sal = 'Average Team Salary per Player'
	  avg_ws = 'Average Player Win Share for Team';
/* linear relationship test */
proc corr data= ws_and_salary plots= scatter ;
var avg_ws team_avg_sal;

data salaries1;
set salaries;
if missing(team) then delete;
if missing(salary) then delete;

proc sql;
create table salary_avg as
select team, avg(salary) as mean format = dollar20.2, median(salary) as median format = dollar20.2
from work.salaries1
group by team;
quit;

proc format;
	value yearfmt 1984-1990 = "1984-1990"
					1991-1995 = "1991-1995"
					1996-2000 = "1996-2000"
					2001-2005 = "2001-2005"
					2006-2010 = "2006-2010"
					2011-2015 = "2011-2015"
					2016 - 2018 = "2016-2018";
run;

ods path(prepend) work.templat(update);
proc template;
 edit base.summary;
  edit mean;
   format=dollar20.2;
  end;
  edit median;

format=dollar20.2;
  end;
    edit qrange;
   format=dollar20.2;
  end;
 end;
run;


proc means data=salaries mean median qrange;
   class end;
   var salary;
   format end yearfmt.;
Run;

data player2;
  set player;
  
run;

proc sort data= player2 out = sort_player;
	by playerid;
	
data merged;
MERGE work.salary_new
	work.sort_player;
BY playerid;
run;

data merged1;
set merged;
if avg <= .Z then delete;
run;

proc sql;
create table positions as
select pos, avg, count(*) as Count
from work.merged1
group by pos
having Count ge 10;
quit;

proc sql;
  select pos, count(*) as count, mean(avg) as mean format=dollar20.2
    from positions
      group by pos
        order by mean descending
  ;
quit;


proc means data = merged1 mean median qrange;
	class PTS;
	var avg;
	format PTS pointsfmt.;
	label PTS = "points per game";
run;






	
