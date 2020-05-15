with sales as 
(
select userid, useremail, contactnumber, amount, creationtime_istdate as "SalesDate"
from orders
where (paymentstatus ilike 'PAID' or paymentstatus ilike 'PARTIALLY_PAID') AND creationtime_istdate between {{Start_Date}} and {{End_Date}} AND amount > 500000
),
MC as
(
select distinct g.userid, count(distinct g.sessionid) as "MCCount"
from gttattendeedetails g
inner join webinarplatform w on g.sessionid = w.sessionid
inner join sales on sales.userid = g.userid
where (starttime_istdate::date between (Salesdate - 90) And Salesdate)
group by 1 
),
VSAT as
(
select distinct u.userid, count(distinct attempted_datetime) as "VSATCount"
from userdetails u
inner join sales on sales.userid = u.userid
where attempted_datetime::date between (Salesdate - 90) And Salesdate AND event ilike '%VSAT%'
group by 1
),
Test as
(
select distinct u1.id, count(distinct testid) as "TestCount"
from contentinfo_testattempts c
inner join public.user u1 on c.student_emails = email
inner join sales on sales.userid = u1.id
inner join clickstream_growthapp cg on u1.id = cg.userid where (timestampist::date  between (Salesdate - 90) And Salesdate AND (eventlabel = 'app_test_ongoing_click' or eventlabel = 'app_test_normal_click')) and duration < 900000 and startedat_istdate between {{Start_Date}} AND {{End_Date}}
group by 1
),
Video as
(
select distinct u1.id, count(cg.userid) as "VideoCount"
from clickstream_growthapp cg
inner join public.user u1 on cg.userid = u1.id
inner join sales on sales.userid = u1.id
where timestampist::date  between (Salesdate - 90) And Salesdate AND (eventlabel = 'app_classroom_video_click' OR eventlabel = 'app_classroom_video_seen')
group by 1
),
IR as 
(
select distinct u1.id, count(ra.userid) as "IRCount"
from replayattendee ra
inner join public.user u1 on ra.userid = u1.id
inner join sales on sales.userid = u1.id
where ra.creationtime_istdate::date between (Salesdate - 90) And Salesdate
group by 1
)

select sales.*, MCCount, VSATCount, TestCount, VideoCount, IRCount
from sales
left join mc on mc.userid = sales.userid
left join vsat on vsat.userid = sales.userid
left join test on test.id = sales.userid
left join video on video.id = sales.userid
left join ir on ir.id = sales.userid
where ((MCCount>0 or VSATCount>0 or TestCount>0 or VideoCount>0 or IRCount>0))
