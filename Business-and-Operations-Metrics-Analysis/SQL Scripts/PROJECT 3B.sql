create table users(
user_id	int primary key,
created_at datetime,
company_id int,
language varchar(20),
activated_at datetime,
state varchar(10)
);
create table email_events(
user_id	int,
occurred_at	datetime,
action	varchar(30),
user_type int
);
create table events(
user_id	int,
occurred_at	datetime,
event_type	varchar(30),
event_name	varchar(30),
location varchar(30),
device	varchar(30),
user_type int
);

/*Weekly User Engagement:
Objective: Measure the activeness of users on a weekly basis.
Your Task: Write an SQL query to calculate the weekly user engagement.*/

WITH abc AS (
    SELECT 
        COUNT(*) AS c1, 
        user_id, 
        YEAR(occurred_at) AS yr1, 
        WEEK(occurred_at) AS wk1
    FROM email_events
    GROUP BY user_id, yr1, wk1
),
def AS (
    SELECT 
        COUNT(*) AS c2, 
        user_id, 
        YEAR(occurred_at) AS yr2, 
        WEEK(occurred_at) AS wk2
    FROM events
    GROUP BY user_id, yr2, wk2
),
left_joined AS (
    SELECT 
        abc.yr1 AS yr3, 
        abc.wk1 AS wk3, 
        COALESCE(abc.c1, 0) + COALESCE(def.c2, 0) AS count, 
        abc.user_id AS u_id
    FROM abc
    LEFT JOIN def 
    ON abc.user_id = def.user_id 
       AND abc.yr1 = def.yr2 
       AND abc.wk1 = def.wk2
),
right_joined AS (
    SELECT 
        def.yr2 AS yr3, 
        def.wk2 AS wk3, 
        COALESCE(abc.c1, 0) + COALESCE(def.c2, 0) AS count, 
        def.user_id AS u_id
    FROM def
    LEFT JOIN abc 
    ON def.user_id = abc.user_id 
       AND def.yr2 = abc.yr1 
       AND def.wk2 = abc.wk1
)
SELECT 
    u_id, 
    yr3 AS year, 
    wk3 AS week, 
    count
FROM left_joined
UNION ALL
SELECT 
    u_id, 
    yr3 AS year, 
    wk3 AS week, 
    count
FROM right_joined
ORDER BY count DESC;


/*User Growth Analysis:
Objective: Analyze the growth of users over time for a product.
Your Task: Write an SQL query to calculate the user growth for the product.*/

/*new users per week*/
select week(created_at) as week, year(created_at) as year, count(*) as no_of_new_users from
users group by week,year order by year;

/*active users*/
select year(occurred_at) as year ,week(occurred_at) week,count(distinct user_id) no_of_active_users from (
select user_id, occurred_at from email_events
union
select user_id, occurred_at from events) as t1 group by year,week order by year;

/*user growth*/
with abc as (
select week(created_at) as week, year(created_at) as year, count(*) as no_of_new_users from
users group by week,year order by year)
select week, year, no_of_new_users, no_of_new_users- lag(no_of_new_users,1,0) over(order by year,week) as change_in_users,
case
when no_of_new_users- lag(no_of_new_users,1,0) over(order by year,week) >0 then "Increase"
when no_of_new_users- lag(no_of_new_users,1,0) over(order by year,week)<0 then "Decrease"
else "No change"
end as growth_insight
from abc;

/*Weekly Retention Analysis:
Objective: Analyze the retention of users on a weekly basis after signing up for a product.
Your Task: Write an SQL query to calculate the weekly retention of users based on their sign-up cohort.*/

WITH abc AS (
    SELECT 
        user_id, 
        YEAR(created_at) AS s_year, 
        WEEK(created_at) AS s_week
    FROM users
),
def AS (
    SELECT 
        user_id, 
        YEAR(occurred_at) AS a_year, 
        WEEK(occurred_at) AS a_week
    FROM (
        SELECT user_id, occurred_at FROM email_events
        UNION
        SELECT user_id, occurred_at FROM events
    ) AS all_events
),
ijk AS (
    SELECT 
        c.s_year,
        c.s_week,
        a.a_year,
        a.a_week,
        COUNT(DISTINCT a.user_id) AS retained_users
    FROM abc c
    join def a on c.user_id = a.user_id
   group by c.s_year,
        c.s_week,
        a.a_year,
        a.a_week,
)
SELECT 
    s_year,
    s_week,
    a_year,
    a_week,
    retained_users
FROM ijk
ORDER BY s_year, s_week, a_year, a_week;

/*Weekly Engagement Per Device:
Objective: Measure the activeness of users on a weekly basis per device.
Your Task: Write an SQL query to calculate the weekly engagement per device.*/
select year(occurred_at) as year, week(occurred_at) as week, device, count(distinct user_id) as no_of_users
from events 
group by device, week, year 
order by week, year;

/*Email Engagement Analysis:
Objective: Analyze how users are engaging with the email service.
Your Task: Write an SQL query to calculate the email engagement metrics.*/
/*finds no of users doing a particular action per week*/
select year(occurred_at) as year, week(occurred_at) as week, action, count(distinct user_id) as no_of_users
from email_events 
group by action, week, year 
order by week, year;

/*finds email events activity per day*/
select 
case
when dayofweek(occurred_at)=0 then "SUN"
when dayofweek(occurred_at)=1 then "MON"
when dayofweek(occurred_at)=2 then "TUE"
when dayofweek(occurred_at)=3 then "WED"
when dayofweek(occurred_at)=4 then "THU"
when dayofweek(occurred_at)=5 then "FRI"
else "SAT"
end as day_of_week, action, count(distinct user_id) as no_of_users
from email_events 
group by action, day_of_week
order by day_of_week;

select user_type, count(user_id) as activities from email_events group by user_type ;

select user_type, year(occurred_at) as yr, week(occurred_at) as wk, count(user_id) as activities from email_events group by yr,wk,user_type
order by wk,yr;

/*find user with most no of email activities per year*/
select user_id, count(action) as no_act, year(occurred_at) as yr
from email_events
group by user_id,yr
order by no_act desc;

with abc as (
select user_id, count(action) as no_act, year(occurred_at) as yr, 
row_number() over (partition by year(occurred_at) order by count(action) desc) as ranks
from email_events
group by user_id, yr
)
select user_id, no_act, yr, ranks
from abc 
order by ranks;
