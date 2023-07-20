
-- Data pulled from https://ourworldindata.org/covid-deaths on 7/17/2023 --

-- Some data clean up done to facilitate mathematical analysis --

--UPDATE CovidDeaths SET total_deaths=NULL WHERE total_deaths=0
--UPDATE CovidDeaths SET total_cases=NULL WHERE total_cases=0
--ALTER TABLE CovidDeaths
--ALTER COLUMN total_cases DECIMAL;
--ALTER TABLE CovidDeaths
--ALTER COLUMN total_deaths DECIMAL;
--ALTER TABLE CovidDeaths
--ALTER COLUMN new_cases DECIMAL;
--ALTER TABLE CovidDeaths
--ALTER COLUMN new_deaths DECIMAL;
--UPDATE CovidDeaths SET new_deaths=NULL WHERE new_deaths=0
--UPDATE CovidDeaths SET new_cases=NULL WHERE new_cases=0

--UPDATE CovidVaccinations SET new_vaccinations=NULL WHERE new_vaccinations=0
--ALTER TABLE CovidVaccinations
--ALTER COLUMN new_vaccinations DECIMAL;


-- Look at both tables created from data --
SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3,4

-- Select Data that we are going to be using
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths  --
-- Shows liklihood of death if you get Covid in your country --
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs Population  --
-- Shows what percentage of population got Covid --
SELECT Location, date, population, total_cases, (total_cases / population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE Location like '%states%'
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to Population  --
SELECT Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases / population))*100 
	as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent != ''
GROUP BY location, population
ORDER BY PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population  --
SELECT Location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent != ''
GROUP BY location
ORDER BY TotalDeathCount desc


-------------------------------
-- Total Deaths by Continent --
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent != ''
GROUP BY continent
ORDER BY TotalDeathCount desc


-- Total Deaths by Continent using Location --
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent = '' AND location not like '%income%'
GROUP BY location
ORDER BY TotalDeathCount desc

-- Total Deaths by income level --
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent = '' AND location like '%income%' OR location like '%world%'
GROUP BY location
ORDER BY TotalDeathCount desc


--GLOBAL NUMBERS--

--SELECT date as "Date", SUM(new_cases) as "New Cases", SUM(new_deaths) as "New Deaths",
--	SUM(new_deaths)/SUM(new_cases)*100 as "Death Percentage"
--FROM PortfolioProject..CovidDeaths
--WHERE continent =''
--GROUP BY date
--ORDER BY 1,2

SELECT SUM(new_cases) as "New Cases", SUM(new_deaths) as "New Deaths",
	SUM(new_deaths)/SUM(new_cases)*100 as "Death Percentage"
FROM PortfolioProject..CovidDeaths
WHERE continent =''
ORDER BY 1,2

--JOIN Deaths with Vaccination tables--
--Total Pop vs Vaccinations--

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
ORDER BY 2,3


-- USE CTE

With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac



--TEMP TABLE



DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		as RollingPeopleVaccinated
--,(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated

-- CREATE VIEW TO STORE DATA FOR VISUALIZATIONS --

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
		as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent != ''

SELECT *
FROM PercentPopulationVaccinated
