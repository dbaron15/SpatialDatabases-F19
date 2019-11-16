-- Lab 3 Task 1

-- add the restaurants and NY county data from lab2 schema
create table lab3.ny_counties_18N as
	select * from lab2.ny_counties;

create table lab3.restaurants as 
	select * from lab2.restaurants;

-- load specific MAPPLUTO data into lab3 schema
create table lab3.mappluto_queens as
	select gid, borough, yearbuilt, assesstot, geom
	from public.mappluto
	where borough = 'QN';
	
-- create UTM 18N geom
alter table lab3.mappluto_queens 
	add column geom_18N geometry(multipolygon, 6347);
	
update lab3.mappluto_queens
	set geom_18N = st_transform(geom, 6347);

--- create spatial index
create index mappluto_queens_18N_idx
	on lab3.mappluto_queens using gist(geom_18N);
	
-- Check ny_counties_18N if valid and/or simple
select st_issimple(geom_18N) as geom_simple, st_isvalid(geom_18N) as geom_valid
from lab3.ny_counties_18N
where st_issimple(geom_18N) is false or st_isvalid(geom_18N) is false;

-- Check mappluto_queens if valid and/or simple
select st_issimple(geom_18N) as geom_simple, st_isvalid(geom_18N) as geom_valid
from lab3.mappluto_queens
where st_issimple(geom_18N) is false or st_isvalid(geom_18N) is false;

-- Lab 3 Task 2

-- Add county name and FIPS columns to restaurant table
alter table lab3.restaurants
	add column county_name varchar(100);
alter table lab3.restaurants
	add column county_fips varchar(3);

-- Update new columns
update lab3.restaurants as rt
	set county_name = ct.name
	from lab3.ny_counties_18N as ct
	where st_within(st_transform(rt.geom, 6347), ct.geom_18N);
update lab3.restaurants as rt
	set county_fips = ct.countyfp
	from lab3.ny_counties_18N as ct
	where st_within(st_transform(rt.geom, 6347), ct.geom_18N);

select * from lab3.restaurants where county_name is not null or county_fips is not null;

-- Create table with restaurants per county
create table lab3.restaurants_per_nyc as
	select rt.county_name, rt.county_fips, -- joined county info
		count(rt.name) as total_count, -- total restaurant count per county
		sum((rt.name = 'MCD')::integer) as mcd_count, -- number of MCD per county
		sum((rt.name = 'PZH')::integer) as pzh_count, -- number of PZH per county
		mode() within group (order by rt.name) as max_chain -- most abundant chain per county
	from lab3.restaurants as rt
	join lab3.ny_counties_18N as ct
	on st_within(st_transform(rt.geom, 6347), ct.geom_18N)
	group by rt.county_name, rt.county_fips;
	
-- Lab 3 Task 3

-- update NULL or <$1k property values to avg value within 800m
-- need to transform to a projection that uses meters like UTM 18N
with mpu as (
	select m.gid, avg(p.assesstot) as avg_assesstot
	from lab3.mappluto_queens as m
	join lab3.mappluto_queens as p
	on st_dwithin(m.geom_18N, p.geom_18N, 800)
	where m.assesstot is null or m.assesstot < 1000
	group by m.gid)
update lab3.mappluto_queens as mpq
	set assesstot = (
		select avg_assesstot from mpu where mpq.gid = mpu.gid
	)
	where mpq.assesstot is null or mpq.assesstot < 1000;

-- find avg assesstot, med assesstot, earliest yearbuilt, number of parcels within 800m of Queens restaurants
with qr as (
	select rt.name, rt.county_name, rt.geom, st_transform(rt.geom, 6347) as geom_18N
	from lab3.restaurants as rt
	where rt.county_name = 'Queens'
)

select qr.name, qr.geom,
	avg(mp.assesstot)::money as avg_assesstot, -- average of assesstot
	percentile_disc(0.5) within group (order by mp.assesstot::money) as med_assesstot, -- median
	min(nullif(mp.yearbuilt, 0)) as earliest_year, -- find the oldest building excluding year = 0
	count(mp.gid) as prop_count -- count of parcels
from lab3.mappluto_queens as mp
join qr
on st_dwithin(mp.geom_18N, qr.geom_18N, 800)
group by qr.name, qr.geom;