--  Explore data and characteristics.

SELECT *
FROM [portfolio].[dbo].[CovidDeaths] d
WHERE d.continent is NULL 
  AND d.location = 'France'
ORDER BY  d.date;

SELECT *
FROM [portfolio].[dbo].[CovidVaccinations] v
WHERE v.continent is NOT NULL 
  AND v.location = 'France'
ORDER BY  v.date;

------------------------------
-- Verify if the total number of records matches, and if the aggregate death count corresponds to the sum of daily death values.

SELECT continent,
         location,
         MIN(date) AS min_date,
         MAX(date) AS max_date,
         COUNT(*) AS tot_records,
         MAX(CAST(total_deaths AS numeric)) AS total_deaths_original,
         SUM(CAST(new_deaths AS numeric)) AS total_deaths_sum,
         MAX(CAST(population AS numeric) / 1000000) AS population_in_million
FROM portfolio.dbo.CovidDeaths AS d
GROUP BY  continent, location
ORDER BY  continent, location, total_deaths_origin DESC

-- Check if the new cases were reported daily.

SET DATEFIRST 1;

WITH newcases_rep AS 
    (SELECT d.date,
			d.location AS country,
			DATEPART(WEEK, D.DATE) WEEK_NUM,
			DATEPART(WEEKDAY,D.DATE) WEEKDAY_NUM,
			cast(d.new_cases AS numeric) new_cases
    FROM [portfolio].[dbo].[CovidDeaths] d
    WHERE 1=1
          -- AND d.location = 'France'
          AND cast(d.new_cases AS numeric) > 0 )

SELECT country,
       weekday_num,
       count(*) total_records ,
       count(weekday_num) OVER (partition by country ) AS total_weekdays
FROM newcases_rep
GROUP BY  country, weekday_num
ORDER BY  4 

-- The data indicates that for many countries, new cases and deaths are reported once a week.
-- Therefore, subsequent analyses will be based on weekly data.

-----------------------------------------------

-- Prepare data for analysis by correcting data type issues and adding missing information (because many columns were uploaded with incorrect data types) 

-- new cases and deaths

SET DATEFIRST 1;

SELECT d.iso_code,
    d.continent,
    d.location,
    d.date,
    CAST(REPLACE(d.population,'.0', '') AS BIGINT) AS population, 
	ROUND(CAST(d.population_density AS FLOAT) / 1000, 2) AS population_density, 
	DATEPART(year,d.date) AS year_num, 
	DATEPART(WEEK,d.date) AS week_num ,
    CASE WHEN 7-datepart(dw,dateadd(dd,1,dateadd(yy,datediff(yy,0,d.date)-1,0))) < 2 
	     THEN datepart(wk,d.date)-1
         ELSE datepart(wk,d.date)
    END AS week_num_corr,
    CASE WHEN datepart(dw, d.date) = 7 THEN d.date END AS date_sunday, 
	CAST(REPLACE(d.new_cases, '.0', '') AS BIGINT) AS new_cases, CAST(REPLACE(d.new_deaths, '.0', '') AS BIGINT) AS new_deaths, 
	cast(d.stringency_index AS numeric(6,2)) AS stringency_index , 
	sum(CAST(REPLACE(d.new_cases, '.0', '') AS BIGINT)) OVER ( partition by d.location ORDER BY  d.date) AS total_cases, 
	round(cast(sum(CAST(REPLACE(d.new_cases, '.0', '') AS BIGINT)) OVER ( partition by d.location ORDER BY  d.date) AS float)*1000000/CAST(REPLACE(d.population, '.0', '') AS BIGINT), 3) AS tot_cases_per_million, 
	sum(CAST(REPLACE(d.new_deaths, '.0', '') AS BIGINT)) OVER ( partition by d.location ORDER BY  d.date) AS total_deaths, 
	round(cast(sum(CAST(REPLACE(d.new_deaths, '.0', '') AS BIGINT)) OVER ( partition by d.location ORDER BY  d.date) AS float)*1000000/CAST(REPLACE(d.population, '.0', '') AS BIGINT),2) AS tot_deaths_per_million
FROM [portfolio].[dbo].[CovidDeaths] d
WHERE d.continent is NOT null
        AND d.location = 'Afghanistan'
ORDER BY  3, 4


-- new vacinations

select v.iso_code, v.continent, v.location, v.date, 
CAST(REPLACE(d.population, '.0', '') AS BIGINT) as population, 
DATEPART(year,v.date) as year_num,
DATEPART(WEEK,v.date) as week_num, 
CAST(REPLACE(v.new_vaccinations, '.0', '') AS BIGINT) AS new_vaccinations,
cast(sum(CAST(REPLACE(v.new_vaccinations, '.0', '') AS BIGINT)) over ( partition by v.location order by v.date) as bigint) as total_vacinations,
cast(cast(v.people_fully_vaccinated as numeric(11,1)) as bigint) as people_fully_vaccinated ,
cast(round(cast(cast(v.people_fully_vaccinated as numeric(11,1)) as bigint)*100/cast(d.population as numeric(11,1)), 2) as numeric(5,2))  as percentage_tot_people_vacinated
from [portfolio].[dbo].[CovidVaccinations] v
inner join [portfolio].[dbo].[CovidDeaths] d
on v.iso_code = d.iso_code
and v.date = d.date
where d.continent is not null
-- where v.location = 'France'
order by v.date;


-----------------
-- Use previous queries to create views

SET DATEFIRST 1;


DROP VIEW IF EXISTS v_CovidDeaths;

USE portfolio
GO
CREATE VIEW v_CovidDeaths 
AS
SELECT d.iso_code,
    d.continent,
    d.location,
    d.date,
    CAST(REPLACE(d.population,'.0', '') AS BIGINT) AS population, 
	ROUND(CAST(d.population_density AS FLOAT) / 1000, 2) AS population_density, 
	DATEPART(year,d.date) AS year_num, 
	DATEPART(WEEK,d.date) AS week_num ,
	DATEPART(iso_week, d.date) as week_iso,  -- to avoid incorrect week number . for examle when 01-01-YYYY belongs to week 52 of the previous year
	CASE WHEN DATEPART(week, d.date) = 1 and DATEPART(iso_week, d.date) > 50 then DATEPART(year,d.date) -1
    ELSE DATEPART(year,d.date)
	END year_iso_corr, --  add first days of the year to the week of the last year in agg
    CASE WHEN datepart(dw, d.date) = 7 THEN d.date END AS date_sunday, 
	CAST(REPLACE(d.new_cases, '.0', '') AS BIGINT) AS new_cases, CAST(REPLACE(d.new_deaths, '.0', '') AS BIGINT) AS new_deaths, 
	cast(d.stringency_index AS numeric(6,2)) AS stringency_index , 
	sum(CAST(REPLACE(d.new_cases, '.0', '') AS BIGINT)) OVER ( partition by d.location ORDER BY  d.date) AS total_cases, 
	round(cast(sum(CAST(REPLACE(d.new_cases, '.0', '') AS BIGINT)) OVER ( partition by d.location ORDER BY  d.date) AS float)*1000000/CAST(REPLACE(d.population, '.0', '') AS BIGINT), 3) AS tot_cases_per_million, 
	sum(CAST(REPLACE(d.new_deaths, '.0', '') AS BIGINT)) OVER ( partition by d.location ORDER BY  d.date) AS total_deaths, 
	round(cast(sum(CAST(REPLACE(d.new_deaths, '.0', '') AS BIGINT)) OVER ( partition by d.location ORDER BY  d.date) AS float)*1000000/CAST(REPLACE(d.population, '.0', '') AS BIGINT),2) AS tot_deaths_per_million
from [portfolio].[dbo].[CovidDeaths] d
where d.continent is not null;

-- check results
select c.*
from [portfolio].[dbo].[v_CovidDeaths] c
where c.location = 'Afghanistan'
order by 3,4

--------------------------

DROP VIEW IF EXISTS v_CovidVaccinations;

USE portfolio
GO
CREATE VIEW v_CovidVaccinations 
AS 
SELECT v.iso_code, 
		v.continent, 
		v.location, 
		v.date, 
		cast(cast(d.population as numeric(11,1)) as bigint) as population, 
		DATEPART(year,v.date) as year_num,
		DATEPART(WEEK,v.date) as week_num, 
		cast(cast(v.new_vaccinations as numeric(11,1)) as bigint) as new_vaccinations,
		cast(sum(cast(v.new_vaccinations as numeric(11,1))) over ( partition by v.location order by v.date) as bigint) as total_vacinations,
		cast(cast(v.people_fully_vaccinated as numeric(11,1)) as bigint) as people_fully_vaccinated,
		cast(round(cast(cast(v.people_fully_vaccinated as numeric(11,1)) as bigint)*100/cast(d.population as numeric(11,1)), 2) as numeric(8,2)) as percentage_tot_people_vacinated
FROM [portfolio].[dbo].[CovidVaccinations] v
JOIN [portfolio].[dbo].[CovidDeaths] d
ON v.iso_code = d.iso_code
AND v.date = d.date
WHERE d.continent is not null;

select * from [portfolio].[dbo].[v_CovidVaccinations] 


-- create a view for data visualization 

DROP VIEW IF EXISTS v_CovidDeathsVaccinations_weekly;

USE portfolio
GO
CREATE VIEW v_CovidDeathsVaccinations_weekly 
AS
SELECT d.iso_code, 
		d.continent, 
		d.location,
		d.year_iso_corr,
		d.week_iso,
		max(d.year_num) as real_year,
		max(d.week_num) as week_num, 
		-- max(cast(d.date_sunday as date)) as date_sunday,
		max(cast(d.date as date)) as date_end_of_week,
		max(d.population) as population,
		max(d.population_density) as population_density,
		sum(d.new_cases) as new_cases,
		max(d.total_cases) as total_cases,
		sum(d.new_deaths) as new_deaths,
		max(d.total_deaths) as total_deaths,
		sum(v.new_vaccinations) as new_vaccinations,
		max(v.total_vacinations) as total_vacinations,
		max(v.people_fully_vaccinated) as people_fully_vaccinated,
		max(d.stringency_index) as stringency_index ,
		max(d.tot_cases_per_million) as tot_cases_per_million,
		max(d.tot_deaths_per_million) as tot_deaths_per_million,
		max(v.percentage_tot_people_vacinated) as percentage_tot_people_vacinated
from [portfolio].[dbo].[v_CovidDeaths] d 
inner join [portfolio].[dbo].[v_CovidVaccinations] v
on v.iso_code = d.iso_code
and v.date = d.date
group by d.iso_code, d.continent, d.location, d.year_iso_corr, d.week_iso;

-------------------------------------------
-- export results to use for data visualisation in Tableau

select *
from [portfolio].[dbo].[v_CovidDeathsVaccinations_weekly]
where  not (year_iso_corr = 2023 and week_iso in (35,36,37))
order by 3,4,5;

------------------
-- Get the number of deaths per million for the entire world for the dashboard

select sum(total_deaths) as global_deaths, 
sum(population) as world_population, 
cast(sum(total_deaths)*1000000/sum(population) as numeric(8,2) ) as global_deaths_per_mil
from (
select c.*, DENSE_RANK() over ( partition by continent, location order by tot_deaths_per_million desc, date_end_of_week asc) as highest_prc_deaths

from [portfolio].[dbo].[v_CovidDeathsVaccinations_weekly] c
where  not (year_iso_corr = 2023 and week_iso in (35,36,37))
) a where highest_prc_deaths = 1
------------------------------------