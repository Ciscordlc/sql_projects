USE PortfolioProject

SELECT *
FROM PortfolioProject..CovidDeaths
--WHERE continent IS NOT NULL
ORDER BY 3, 4


-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2


-- Looking at total cases vs total deaths
-- Shows percentage of death vs covid infection in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS death_percentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1, 2

-- Looking at total cases vs population over time
SELECT location, date, population, total_cases, (total_cases/population) * 100 AS infected_percentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%states%'
ORDER BY 1, 2


-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population) * 100) AS infected_percentage
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY infected_percentage DESC


-- Showing countries with highest death count per population per country
SELECT location, population, MAX(CAST(total_deaths AS int)) AS total_death_count, MAX((total_deaths/population) * 100) AS death_percentage
FROM PortfolioProject..CovidDeaths
--WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_death_count DESC


-- Showing continents with highest death count and death percentage
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count, MAX((total_deaths/population) * 100) AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location IN ('Europe', 'North America', 'Asia', 'South America', 'Africa', 'Oceania')
GROUP BY location
ORDER BY total_death_count DESC

-- For tableau
SELECT continent, MAX(CAST(total_deaths AS int)) AS total_death_count, MAX((total_deaths/population) * 100) AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC


-- Global numbers
SELECT date, SUM(new_cases) AS new_global_cases, SUM(CAST(new_deaths AS int)) AS new_global_deaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases)) * 100 AS global_death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2


-- Showing total population vs new vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_total_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- Using common table expression (CTE) to get the rolling total vaccinations percentage
WITH PopVsVac (continent, location, date, population, new_vaccinations, rolling_total_vaccinations)
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_total_vaccinations/population) * 100 AS percentage_population_vaccinated
FROM PopVsVac
ORDER BY 2, 3


-- Using a temp table to get the rolling total vaccinations count
-- Not using the standard # in the name to keep the temp table in the portfolio project db
DROP TABLE IF EXISTS TempPercentPopulationVaccinated

CREATE TABLE TempPercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccination numeric,
	RollingPeopleVaccinated numeric
)

INSERT INTO TempPercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS rolling_total_vaccinations
From TempPercentPopulationVaccinated
WHERE location LIKE '%states%'


-- Creating view to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated

CREATE VIEW PercentPopulationVaccinated 
AS (
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION by dea.location ORDER BY dea.location, dea.date) AS rolling_total_vaccinations
	FROM PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
		ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)

SELECT *
FROM PercentPopulationVaccinated