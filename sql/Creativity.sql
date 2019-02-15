--------
-- e2 --
--------

---------------------------------------------
-- Solving duration and rate per word on E2
---------------------------------------------
select word,
		min_duration,
		max_duration,
		avg_duration,
		total_users_guesses,
		total_users,
		pct_users
from (select *, 
			count(b.user_id) over(partition by a.word) as total_users_guesses,
			(select count(distinct user_id) from complete_sessions) as total_users,
			count(b.user_id) over(partition by a.word)/(select count(distinct user_id) from complete_sessions)::float as pct_users
		from (
				select creativity.word,
					round(cast(min("durationFromStartTyping") as numeric),0) as min_duration,
					round(cast(max("durationFromStartTyping") as numeric),0) as max_duration,
					round(cast(avg("durationFromStartTyping") as numeric),0) as avg_duration
				from complete_sessions 
				left join df_live_creativity as creativity on creativity."userID" = complete_sessions.user_id
				where mode = 'live'
				and "hintsShown" is false
				group by 1
				)a
				
		left join (
					select user_id, creativity.word--
					from complete_sessions 
					left join df_live_creativity as creativity on creativity."userID" = complete_sessions.user_id
					where mode = 'live'
					and "hintsShown" is false
					)b
			using (word)
	)c
group by 1,2,3,4,5,6,7


---------------------------------------------
-- aggregated solving speed for creativity test PM1 --
---------------------------------------------
-- create view e2_metrics_PM1 as
select user_id,
		session_id,
		round(cast(min(case when "durationFromStartTyping" < 30000 and "hintsShown" is false then "durationFromStartTyping" end)/1000 as numeric),1) as e2_min_duration_per_word,
		round(cast(max(case when "durationFromStartTyping" < 30000 and "hintsShown" is false then "durationFromStartTyping" end)/1000 as numeric),1) as e2_max_duration_per_word,
		round(cast(avg(case when "durationFromStartTyping" < 30000 and "hintsShown" is false then "durationFromStartTyping" end)/1000 as numeric),1) as e2_avg_duration_per_word,
		sum(case when "hintsShown" is false then total_guesses end) as e2_success_rate
from (select complete_sessions.user_id,
			complete_sessions.session_id,
			creativity.word,
			"hintsShown",
			sum("durationFromStartTyping") as "durationFromStartTyping",
			count(*) as total_guesses
	from complete_sessions 
	left join df_live_creativity as creativity on creativity."userID" = complete_sessions.user_id
	where mode = 'live'
	group by 1,2,3,4) a
group by 1,2--, "hintsShown","durationFromStartTyping"
order by 1,2

---------------------------------------------
-- solving speed in seconds per word for creativity test PM2--
---------------------------------------------
-- create view e2_metrics_PM2 as
select * from df_inv_solving_speed

	
---------------------------------------------
-- idea_rate and, correct choices and negative attention
-- (PM3 PM4 PM5)
---------------------------------------------
-- create view e2_metrics_PM3_PM4_PM5 as
select "userID",
		"sessionID",
		sum(incorrect_attempts) + sum(correct_guesses) as e2_idea_rate,
		sum(correct_guesses) as e2_correct_guesses,
		sum(bad_hintclicks) as e2_sum_bad_hintclicks,
		coalesce(sum(bad_hintclicks) / nullif((20 - sum(correct_guesses)),0),0) as e2_neg_attention_ratio
from(select df_live_events."userID",
			df_live_events."sessionID",
			df_live_events.word,
			sum(case when name = 'creativity_wordset_incorrect' and timestamp < wordSet_expired then 1 else 0 end) as incorrect_attempts,
			sum(case when name = 'creativity_wordset_incorrect' and timestamp > wordSet_expired then 1 else 0 end) as bad_hintclicks,
			sum(case when name = 'creativity_wordset_correct' and (timestamp < wordSet_expired or wordSet_expired is null) then 1 else 0 end) as correct_guesses
	from df_live_events
	join complete_sessions using("sessionID")
	left join   (select "sessionID",
					word,
					timestamp as wordSet_expired
				from df_live_events
				join complete_sessions
				using("sessionID")
				where name = 'creativity_wordset_expired'
				and mode = 'live'
				) a 
	on complete_sessions."sessionID" = a."sessionID" and df_live_events.word = a.word
	where mode = 'live'
	group by 1,2,3)alias
group by 1,2
