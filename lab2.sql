-- Lab 2 Task 2
create extension postgis;

--- create and load restaurants table
create table lab2.restaurants (
	name char(3),
	lat float8,
	lon float8);
	
copy lab2.restaurants from 'F:\GTECH785-Databases\postgis_in_action_2e_code_data\ch01\data\restaurants.csv'
	delimiter ',' CSV;
	
--- create geometry and geography columns
alter table lab2.restaurants 
	add column geom geometry(point, 4326);
alter table lab2.restaurants 
	add column geog geography(point, 4326);

--- update columns
update lab2.restaurants
	set geom = ST_SetSRID(ST_MakePoint(lon, lat), 4326);

update lab2.restaurants
	set geog = CAST(geom as geography);

select st_srid(geom) as Geom_SRID, st_srid(geog) as Geog_SRID
	from lab2.restaurants;

-- Lab 2 Task 3
create extension postgis;
alter extension postgis update;
 
--- create NY counties table
create table lab2.ny_counties as
	select *
	from lab2.cb_2018_us_county_500k
	where statefp = '36';

--- add UTM18N geom column
alter table lab2.ny_counties 
	add column geom_18N geometry(multipolygon, 6347);

--- update geometry to UTM 18N
update lab2.ny_counties
	set geom_18N = st_transform(geom, 6347);
	
select geom_18N, st_srid(geom_18N) as Geom_SRID
	from lab2.ny_counties;
	
select find_srid('lab2', 'ny_counties', 'geom_18n');
	
--- create spatial index on new UTM18N column
create index ny_counties_18N_idx
	on lab2.ny_counties using gist(geom_18N);