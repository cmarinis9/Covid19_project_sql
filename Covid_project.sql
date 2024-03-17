-- Quick overview of the data sorted by country
select * 
from PortfolioProject..covid_19_data$ 
order by 4

select [Country/Region],Confirmed,Deaths,Recovered
from PortfolioProject..covid_19_data$ 

-- Looking at Recovered vs Confirmed(first method)
select [Country/Region],Confirmed,Deaths,Recovered,
(Recovered/nullif(confirmed,0)) * 100 as Recovery_rate
from PortfolioProject..covid_19_data$

-- Quick overview of the data for Greece with recovery rate calculated(second method handle devided by zero)
SELECT [Country/Region], Confirmed, Deaths, Recovered,
CASE 
    WHEN Confirmed = 0 THEN NULL 
    ELSE (Recovered / Confirmed)* 100
END AS Recovery_Rate
FROM PortfolioProject..covid_19_data$
where [Country/Region] like '%Greece%'

-- Looking at Deaths vs Confirmed cases 
select ObservationDate,[Country/Region],Confirmed,Deaths,Recovered,
(Deaths/nullif(confirmed,0)) * 100 as Deaths_rate
from PortfolioProject..covid_19_data$
where [Country/Region] like '%GR%'
 
--looking at the Deaths_rate at a specific time for country/region starting with "Gr"
SELECT ObservationDate, [Country/Region], Confirmed, Deaths, Recovered,
       (Deaths / NULLIF(Confirmed, 0)) * 100 AS Deaths_rate
FROM PortfolioProject..covid_19_data$
WHERE [Country/Region] LIKE '%Gr%' AND ObservationDate = '06/25/2020'

--looking at Countries with highest confirmed cases and sorted by descenting order
select [Country/Region],MAX(Confirmed) AS HighestInfectionCount,
MAX((Deaths/nullif(confirmed,0)) * 100) as MaxDeaths_Percentage
from PortfolioProject..covid_19_data$
Group by [Country/Region]
order by HighestInfectionCount desc

-- Looking at Countries with the highest confirmed cases and a minimum number of deaths
SELECT [Country/Region],MAX(Confirmed) AS HighestInfectionCount,MAX(Deaths) as DeathsCount,
       MAX((Deaths / NULLIF(Confirmed, 0)) * 100) AS MaxDeaths_Percentage
FROM PortfolioProject..covid_19_data$
GROUP BY [Country/Region]
HAVING MAX(Confirmed) > 1000 AND MAX(Deaths) < 10
ORDER BY HighestInfectionCount 


--looking for a specified country/region
SELECT [Country/Region],MAX(Confirmed) AS HighestInfectionCount,MAX(Deaths) as DeathsCount,
       MAX((Deaths / NULLIF(Confirmed, 0)) * 100) AS MaxDeaths_Percentage
FROM PortfolioProject..covid_19_data$
WHERE [Country/Region]  like '%Gre%'
GROUP BY [Country/Region]
ORDER BY HighestInfectionCount DESC

-- Looking at Countries with the highest Deaths and specifically adding a filter, sorted by ascending order
select [Country/Region],MAX(Deaths) AS HighestDeathsCount
from PortfolioProject..covid_19_data$
Group by [Country/Region]
Having MAX(Deaths) > 1000
order by HighestDeathsCount
 
-- Unveiling the Monthly Impact: Breaking down the deadliest months by Country
SELECT MONTH(ObservationDate) AS ObservationMonth,[Country/Region], MAX(Deaths) AS total_deaths
FROM PortfolioProject..covid_19_data$
WHERE ObservationDate IS NOT NULL
GROUP BY MONTH(ObservationDate),[Country/Region]
ORDER BY total_deaths DESC


--Inner join
select * 
from PortfolioProject..covid_19_data$ dea 
join PortfolioProject..CovidVaccinations$ vac
on dea.[Country/Region] = vac.location
and dea.ObservationDate = vac.date

--Unveiling the COVID Landscape: Mapping Confirmed cases,Deaths and Recovered
SELECT 
    vac.continent, 
    vac.location, 
    dea.ObservationDate, 
    dea.Confirmed, 
    dea.Deaths,
    dea.Recovered,
    SUM(dea.Confirmed) OVER (PARTITION BY vac.location) AS TotalConfirmed
FROM 
    PortfolioProject..covid_19_data$ dea 
JOIN 
    PortfolioProject..CovidVaccinations$ vac
	ON dea.[Country/Region] = vac.location
	AND dea.ObservationDate = vac.date
ORDER BY 
    2, 3


-- Creating a CTE to prepare the data needed for the main query.
WITH total_confirmed_cases_by_country AS (
    SELECT 
        vac.location AS country,
        SUM(dea.Confirmed) AS total_confirmed_cases
    FROM 
        PortfolioProject..covid_19_data$ dea 
    JOIN 
        PortfolioProject..CovidVaccinations$ vac
        ON dea.[Country/Region] = vac.location
        AND dea.ObservationDate = vac.date
    GROUP BY 
        vac.location
)

SELECT 
    country,
    total_confirmed_cases
FROM 
    total_confirmed_cases_by_country
ORDER BY 
    country



-- Using Temp Table to perform Calculation on Partition By in previous query
DROP TABLE IF EXISTS #total_confirmed_cases_by_country

CREATE TABLE #total_confirmed_cases_by_country
(
    country NVARCHAR(255),
    total_confirmed_cases INT
)


INSERT INTO #total_confirmed_cases_by_country
SELECT 
    vac.location AS country,
    SUM(dea.Confirmed) AS total_confirmed_cases
FROM 
    PortfolioProject..covid_19_data$ dea 
JOIN 
    PortfolioProject..CovidVaccinations$ vac
    ON dea.[Country/Region] = vac.location
    AND dea.ObservationDate = vac.date
GROUP BY 
    vac.location;

SELECT 
    *,
   (total_confirmed_cases * 100.0)  / SUM(total_confirmed_cases) over() percentage_confirmed_of_total
FROM 
    #total_confirmed_cases_by_country


--Creating a view to store data for later visualizations
CREATE VIEW total_confirmed_cases_by_country as 
SELECT 
        vac.location AS country,
        SUM(dea.Confirmed) AS total_confirmed_cases
    FROM 
        PortfolioProject..covid_19_data$ dea 
    JOIN 
        PortfolioProject..CovidVaccinations$ vac
        ON dea.[Country/Region] = vac.location
        AND dea.ObservationDate = vac.date
    GROUP BY 
        vac.location

-- Running this query to validate the accuracy and functionality
SELECT *
FROM total_confirmed_cases_by_country 

--Another useful view
CREATE VIEW monthly_impact_of_covid_by_country as 
SELECT MONTH(ObservationDate) AS ObservationMonth,[Country/Region], MAX(Deaths) AS total_deaths
FROM PortfolioProject..covid_19_data$
WHERE ObservationDate IS NOT NULL
GROUP BY MONTH(ObservationDate),[Country/Region]

SELECT * 
FROM monthly_impact_of_covid_by_country






	































