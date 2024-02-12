

--SELECT Location , date , total_cases , new_cases , total_deaths , population
--FROM [ProfolioProject]..CovidDeaths$
--order by 1,2


SELECT Location , date , total_cases   , total_deaths , (total_deaths/total_cases) *100 as deathpercentage
FROM [ProfolioProject]..CovidDeaths$
where location = 'United states'
order by 1,2

--total cases vs population

SELECT Location , date , total_cases   , population , (total_cases/population) *100 as infectionpercentage
FROM [ProfolioProject]..CovidDeaths$
where location = 'Turkey'
order by 1,2

--show the country with the highest infection rate

SELECT Location  , MAX(total_cases) as highestInfectioncount   , population , MAX((total_cases/population)) *100  as infectionpercentage
FROM [ProfolioProject]..CovidDeaths$
group by population , location
order by 4 DESC

-- show the country with the highest death rates

SELECT Location  , MAX(cast(total_deaths as int)) as highestDeathcount    
FROM [ProfolioProject]..CovidDeaths$
where continent is not null
group by  location
order by highestDeathcount DESC

-- show the continent with the highest death rates
SELECT location  , MAX(cast(total_deaths as int)) as highestDeathcount    
FROM [ProfolioProject]..CovidDeaths$
where continent is  null
group by  location
order by highestDeathcount DESC


-- global states


SELECT date , SUM(cast(new_cases as int)) GlobalCases, SUM(cast(new_deaths as int)) as GlobalDeaths , SUM(cast(new_deaths as int))/SUM(new_cases) *100 as GlobalDeathPercentage
FROM [ProfolioProject]..CovidDeaths$
where continent is not null
GROUP BY date
order by 1,2

--total vaccinations vs population
SELECT dea.continent , dea.location , dea.date , dea.population , vac.new_vaccinations
, SUM(CONVERT(int , vac.new_vaccinations)) OVER(PARTITION BY dea.location , dea.date order by dea.location , dea.date)
FROM [ProfolioProject].dbo.CovidDeaths$ as dea
	join [ProfolioProject].dbo.CovidVaccinations$ as vac
	ON dea.location = vac.location and dea.date = vac.date
	where dea.continent is not null
order by 2,3


--CTE of the total vaccinations vs population:

WITH VaccinatedPopulation (continent , location , date,Population,new_vaccinations,RollingPeopleVaccinated)
as
(
SELECT dea.continent , dea.location , dea.date , dea.population , vac.new_vaccinations
, SUM(CONVERT(int , vac.new_vaccinations)) OVER(PARTITION BY dea.location  order by dea.location , dea.date) as RollingPeopleVaccinated

FROM [ProfolioProject].dbo.CovidDeaths$ dea
	join [ProfolioProject].dbo.CovidVaccinations$ as vac
	ON dea.location = vac.location and dea.date = vac.date
	where dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated / Population)*100 as percentageOfVaccinatedPeople
FROM VaccinatedPopulation 


--TEMP TABLE
DROP TABLE IF EXISTS #PercentageOfvaccs;

CREATE TABLE #PercentageOfvaccs
(
    Continent NVARCHAR(225),
    Location NVARCHAR(225),
    Date DATETIME,
    New_vacc NUMERIC,
    Population NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentageOfvaccs 
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    vac.new_vaccinations,
    dea.population,
    SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    [ProfolioProject].dbo.CovidDeaths$ dea
JOIN 
    [ProfolioProject].dbo.CovidVaccinations$ AS vac ON dea.location = vac.location AND dea.date = vac.date;

SELECT 
    *,
    CASE 
        WHEN Population <> 0 THEN (RollingPeopleVaccinated / Population) * 100 
        ELSE 0 -- or any other default value you prefer
    END AS percentageOfVaccinatedPeople
FROM 
    #PercentageOfvaccs
