--------
-- e1 --
--------

---------------------------------------------
-- Memory metrics: --
-- PM1 total duration of game in seconds
-- PM2 pairs opened
-- PM5 false_guesses
-- PM4 opens_per_minute
-- clicks when card is inactive (haste)
-- PM3 pairs_open_before_first_miss
---------------------------------------------
-- create view e1_metrics as
select df_live_events."sessionID",
		source,
		gender,
		round((sum(case when name = 'memory_finish' then "timestamp" end) - sum(case when name = 'memory_closePositions' then "timestamp" end))/1000,0) as e1_total_duration_seconds,
		sum(case when name = 'memory_cardMiss' or name = 'memory_cardMatch' then 1 else 0 end) as e1_pairs_opened,
		sum(case when name = 'memory_cardMiss' then 1 else 0 end) as e1_false_guesses,
		round(sum(case when description ilike 'click on card%' then 1 else 0 end)/((sum(case when name = 'memory_finish' then "timestamp" end) - sum(case when name = 'memory_closePositions' then "timestamp" end))/60000),0) as e1_opens_per_minute,
		sum(case when description = 'click on tile when it''s inactive' then 1 else 0 end) as e1_inactive_clicks,
		sum(case when description ilike 'click on card%' and timestamp < first_miss then 1 else 0 end)/2 as e1_pairs_open_before_first_miss
from df_live_events
join complete_sessions using("sessionID")
left join   (select "sessionID",
				min(timestamp) as first_miss
			from df_live_events
			join complete_sessions
			using("sessionID")
			where name = 'memory_cardMiss'
			group by 1
			) a 
on complete_sessions."sessionID" = a."sessionID"
-- where mode = 'live'
group by 1,2,3


--
select "sessionID", avg(clickdifference), min(clickdifference), max(clickdifference) from (
	select *,
		case when "clickResult" = 'card1' and lead("clickResult") over (partition by "sessionID" order by "timestamp") = 'card2' then lead("timestamp") over (partition by "sessionID" order by "timestamp") - "timestamp" end as clickDifference
	from df_live_events
	join complete_sessions using("sessionID")
	where "clickResult" in ('card1', 'card2')
) alias
group by 1


select "sessionID", clickdifference from (
	select *,
		case when "clickResult" = 'card1' and lead("clickResult") over (partition by "sessionID" order by "timestamp") = 'card2' then lead("timestamp") over (partition by "sessionID" order by "timestamp") - "timestamp" end as clickDifference
	from df_live_events
	join complete_sessions using("sessionID")
	where "clickResult" in ('card1', 'card2')
) as a 
where a.clickdifference > 5000

	