SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccination
ORDER BY 3,4

--Select data that we are going to be using
SELECT location, date, total_cases, total_deaths, new_cases, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Looking at Total_cases VS Total_deaths
SELECT location, date, total_cases, total_deaths, CONVERT(INT, total_deaths)/CONVERT(int, total_cases) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Using WHERE
SELECT location, date, total_cases, total_deaths, CAST(total_deaths AS INT)/CAST(total_cases AS INT) AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%state%'
ORDER BY 1,2

--SHOW LIKELIHOOD OF DYING IF YOU CONTRACT COVID IN UR COUNTRY
--Looking at Total_cases VS population

SELECT location, date, total_cases, population, CONVERT(float, total_cases)/CONVERT(float,population)*100 AS PercentofContract
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--FIND THE HIGHEST DEATHS IN EACH OF COUNTRY
SELECT location, MAX(convert(int, total_deaths)) AS totaldeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY totaldeaths DESC

--let's break thing down by continent
SELECT location, MAX(CONVERT(int, total_deaths)) AS totaldeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY totaldeaths DESC

--Looking at Countries with Highest Infection Rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(CONVERT(float, total_cases))/CONVERT(float, population)*100 AS InfectionRate
FROM PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY InfectionRate DESC

--Find the Highest Deaths In each Continent?

SELECT continent, MAX(CONVERT(int, total_deaths)) AS totaldeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY totaldeaths DESC

--Showing the continents with the highest death count per population?
SELECT continent, population, MAX(CONVERT(int, total_deaths)) AS MaxTotalDeath, MAX(CONVERT(FLOAT, total_deaths))/CONVERT(float, population) AS DeathPerPopulation
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, population
ORDER BY MaxTotalDeath DESC

-- Using SUM() 
SELECT date, SUM(new_cases) AS allnewcases, SUM(new_deaths) AS allnewdeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
order by 1,2

--Global Number
SELECT date, total_cases, total_deaths, CONVERT(int, total_deaths)/CONVERT(int, total_cases) AS PercentOfDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date, total_cases, total_deaths

--TINH new_deaths / new_cases
SELECT date, SUM(new_cases) AS allnewcases, SUM(new_deaths) AS allnewdeaths, 
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE SUM(new_deaths)/SUM(new_cases)
END AS DeathsRate
FROM PortfolioProject..CovidDeaths
GROUP BY date
order by 1,2

--Chosse sum
SELECT SUM(new_cases) AS allnewcases, SUM(new_deaths) AS allnewdeaths, SUM(new_deaths)/SUM(new_cases) AS percentofdeath
FROM PortfolioProject..CovidDeaths
order by 1,2

--JOIN- Gop 2 bang
SELECT *
FROM PortfolioProject..CovidDeaths Dea
JOIN PortfolioProject..CovidVaccination Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date

--LOOKING AT Total population and Vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, new_vaccinations))
OVER(PARTITION BY dea.location) AS RollingVaccine
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 2,3


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, new_vaccinations))
OVER(PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccine
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 2,3


-- New_Vaccinations / population?
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, new_vaccinations)) 
OVER(PARTITION BY dea.location ORDER BY dea.date) AS RollingVaccine,
(RollingVaccine/dea.population)*100 AS PercentOfVaccine
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
ORDER BY 2,3

--CAN NOT USE NEW COLUMN TO DIVIDE

--USE CTE
WITH PopVsVac(continent, location, date, population, new_vaccinations, RollingVaccine)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, new_vaccinations)) 
	OVER(PARTITION BY dea.location ORDER BY dea.date) 
	AS RollingVaccine
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL
)

SELECT *, (RollingVaccine/population)*100 AS PercentOfVaccine
FROM PopVsVac



--USING TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
( 
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
RollingVaccine numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, new_vaccinations)) 
	OVER(PARTITION BY dea.location ORDER BY dea.date) 
	AS RollingVaccine
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL

SELECT *, (RollingVaccine/population)*100 AS PercentOfVaccine
FROM #PercentPopulationVaccinated

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint, new_vaccinations)) 
	OVER(PARTITION BY dea.location ORDER BY dea.date) 
	AS RollingVaccine
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccination vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND vac.new_vaccinations IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated
