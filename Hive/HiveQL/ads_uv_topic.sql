
--------------------------------------------------------------
drop table if exists ads_uv_count;
create external table ads_uv_count( 
    `dt` string COMMENT '统计日期',
    `day_count` bigint COMMENT '当日活跃设备数量',
    `wk_count`  bigint COMMENT '当周活跃设备数量',
    `mn_count`  bigint COMMENT '当月活跃设备数量',
    `is_weekend` string COMMENT 'Y或N表示是否是周末,用于得到本周最终结果',
    `is_monthend` string COMMENT 'Y或N表示是否是月末,用于得到本月最终结果' 
) COMMENT '活跃设备数表'
row format delimited fields terminated by '\t'
location '/warehouse/gmall/ads/ads_uv_count/';
--------------------------------------------------------------

--------------------------------------------------------------
insert into table ads_uv_count 
select  
    '2020-03-10' dt,
    daycount.ct,
    wkcount.ct,
    mncount.ct,
    if(date_add(next_day('2020-03-10','MO'),-1)='2020-03-10','Y','N') ,
    if(last_day('2020-03-10')='2020-03-10','Y','N') 
from 
(
    select  
        '2020-03-10' dt,
        count(*) ct
    from dwt_uv_topic
    where login_date_last='2020-03-10'  
)daycount join 
( 
    select  
        '2020-03-10' dt,
        count (*) ct
    from dwt_uv_topic
    where login_date_last>=date_add(next_day('2020-03-10','MO'),-7) 
    and login_date_last<= date_add(next_day('2020-03-10','MO'),-1) 
) wkcount on daycount.dt=wkcount.dt
join 
( 
    select  
        '2020-03-10' dt,
        count (*) ct
    from dwt_uv_topic
    where date_format(login_date_last,'yyyy-MM')=date_format('2020-03-10',
'yyyy-MM')  
)mncount on daycount.dt=mncount.dt;
--------------------------------------------------------------


--------------------------------------------------------------
drop table if exists ads_new_mid_count;
create external table ads_new_mid_count
(
    `create_date`     string comment '创建时间' ,
    `new_mid_count`   BIGINT comment '新增设备数量' 
)  COMMENT '每日新增设备数表'
row format delimited fields terminated by '\t'
location '/warehouse/gmall/ads/ads_new_mid_count/';
--------------------------------------------------------------

--------------------------------------------------------------
insert into table ads_new_mid_count 
select
    login_date_first,
    count(*)
from dwt_uv_topic
where login_date_first='2020-03-10'
group by login_date_first;
--------------------------------------------------------------

--------------------------------------------------------------
drop table if exists ads_silent_count;
create external table ads_silent_count( 
    `dt` string COMMENT '统计日期',
    `silent_count` bigint COMMENT '沉默设备数'
)COMMENT '沉默设备数'
row format delimited fields terminated by '\t'
location '/warehouse/gmall/ads/ads_silent_count';
--------------------------------------------------------------

--------------------------------------------------------------
insert into table ads_silent_count
select
    '2020-03-15',
    count(*) 
from dwt_uv_topic
where login_date_first=login_date_last
and login_date_last<=date_add('2020-03-15',-7);
--------------------------------------------------------------

--------------------------------------------------------------
drop table if exists ads_back_count;
create external table ads_back_count( 
    `dt` string COMMENT '统计日期',
    `wk_dt` string COMMENT '统计日期所在周',
    `wastage_count` bigint COMMENT '回流设备数'
) COMMENT '本周回流设备数'
row format delimited fields terminated by '\t'
location '/warehouse/gmall/ads/ads_back_count';
--------------------------------------------------------------

--------------------------------------------------------------
insert into table ads_back_count
select
    '2020-03-15',
    count(*)
from
(
    select
        mid_id
    from dwt_uv_topic
    where login_date_last>=date_add(next_day('2020-03-15','MO'),-7) 
    and login_date_last<= date_add(next_day('2020-03-15','MO'),-1)
    and login_date_first<date_add(next_day('2020-03-15','MO'),-7)
)current_wk
left join
(
    select
        mid_id
    from dws_uv_detail_daycount
    where dt>=date_add(next_day('2020-03-15','MO'),-7*2) 
    and dt<= date_add(next_day('2020-03-15','MO'),-7-1) 
    group by mid_id
)last_wk
on current_wk.mid_id=last_wk.mid_id
where last_wk.mid_id is null;
--------------------------------------------------------------


