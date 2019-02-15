	
---------------------------------------------
-- Complete sessions with user attributes --
---------------------------------------------
	
select sessions.*, 
	users.index as user_id,
	sessions.index as session_id,
	users.age,
	users.gender,
	users.education,
	users.englishlevel,
	users.native
from df_live_sessions as sessions
join df_live_users as users on "userID"=users.index 
where started is not null
and finished is not null

---------------------------------------------
-- Completed sessions view creation --
---------------------------------------------
create view complete_sessions as (
		select sessions.*, 
	users.index as user_id,
	sessions.index as session_id,
	users.age,
	users.gender,
	users.education,
	users.englishlevel,
	users.native
from df_live_sessions as sessions
join df_live_users as users on "userID"=users.index 
where started is not null
and finished is not null
		)
		
---------------------------------------------
-- Count of respondents by source --
---------------------------------------------
select case when source is null then 'social' else source end as source,
		count(*) as source
from complete_sessions
group by 1

---------------------------------------------
-- complete sessions duration in minutes --
---------------------------------------------
select "sessionID", englishlevel, native, round(cast((finished-started)/1000 as numeric) / 60, 2) as duration
from complete_sessions;

---------------------------------------------
-- count all started sessions per user --
---------------------------------------------
select users.index, 
		count(*)
from df_live_sessions as sessions
left join df_live_users as users on sessions."userID"=users.index 
group by 1;

---------------------------------------------
-- sessions complete per user --
---------------------------------------------
select users.index, 
		count(*)
from df_live_sessions as sessions
left join df_live_users as users on "userID"=users.index 
where started is not null
and finished is not null
group by 1;

------------------------------------------------
-- distribution of preconditioning and theme ---
------------------------------------------------
select preconditioning,
		"themeVersion",
		count(*)
from df_live_sessions
where started is not null
and finished is not null
group by 1,2;




---------------------------------------------
-- View for e1 --
---------------------------------------------	
		
select * from e1_metrics

---------------------------------------------
-- View for e2 --
---------------------------------------------

select * from e2_metrics_pm1
select * from e2_metrics_pm2
select * from e2_metrics_pm3_pm4_pm5

---------------------------------------------
-- All together now --
---------------------------------------------

select 
	a.session_id,
	a.user_id,
	a."source",
	a.preconditioning,
	a."themeVersion",
	a.arousal_preprecond, a.arousal_pre, a.arousal_post,
	a.valence_preprecond, a.valence_pre, a.valence_post,
	a.age,
	a.gender,
	a.education,
	a.englishlevel,
	a.native,
	e1.e1_total_duration_seconds,
	e1.e1_pairs_opened, e1.e1_false_guesses, e1.e1_opens_per_minute, e1.e1_inactive_clicks, e1.e1_pairs_open_before_first_miss,
	e21.e2_avg_duration_per_word,
	"word.bag", "word.ball", "word.band", "word.boat", "word.chair", "word.family", 
	"word.fast", "word.fire", "word.forest", "word.gold", "word.hole", 
	"word.honey", "word.party", "word.salt", "word.school", "word.soap", 
	"word.sore", "word.sugar", "word.tape", "word.watch",
	e23.e2_idea_rate, e23.e2_correct_guesses, e23.e2_sum_bad_hintclicks, e23.e2_neg_attention_ratio
from 
complete_sessions as a
left join e1_metrics as e1 on e1."sessionID" = a."sessionID"
left join e2_metrics_pm1 as e21 on e21.session_id = a."sessionID"
left join e2_metrics_pm2 as e22 on e22."sessionID" = a."sessionID"
left join e2_metrics_pm3_pm4_pm5 as e23 on e23."sessionID" = a."sessionID"

SELECT "userID", "sessionID", 
