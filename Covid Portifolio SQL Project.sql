SELECT *
FROM PortifolioProject.dbo.['covidVaccinations']
ORDER BY 3,4;


--SELECTING THE DATA WE ARE GOING TO BE USING

SELECT Location, date, total_cases, new_cases, total_deaths, population 
FROM PortifolioProject..CovidDeaths
ORDER BY 1,2


--LOOKING AT TOTAL CASES VS TOTAL DEATHS
--shows the likelihood of dying if you contract covid in Zambia
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 DeathPercentage
FROM PortifolioProject..CovidDeaths
WHERE LOCATION LIKE '%Zambia%'
ORDER BY 1,2

--had to change total_cses to float
ALTER TABLE PortifolioProject..CovidDeaths
ALTER COLUMN total_cases float;

--Looking at Total Cases vs Population
--shows what percentage of population got covid
SELECT Location, date, total_cases, population, (total_cases/population)*100 CovidPercentage
FROM PortifolioProject..CovidDeaths
WHERE LOCATION LIKE '%Zambia%'
ORDER BY 1,2

--looking at countris with highest infection rate compared to population
SELECT Location, population, MAX(total_cases) HighestInfection, MAX((total_cases/population))*100 CovidPercentage
FROM PortifolioProject..CovidDeaths
--WHERE LOCATION LIKE '%Zambia%'
GROUP BY Location, population
ORDER BY 4 desc

--showing countries witht the highest death count per population
SELECT Location, MAX(CAST(total_deaths as float)) TotalDeathPercentage
FROM PortifolioProject..CovidDeaths
where continent is not null
GROUP BY Location 
ORDER BY 2 desc

--lets break things down by continent

--Showing the continents with the highest death count
SELECT continent, MAX(total_deaths) TotalDeathCount
FROM PortifolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent 
ORDER BY 2 desc;


--GLOBAL NUMBERS
SELECT Date, SUM(total_cases) Total_Cases, SUM(CAST(total_deaths as float)) as
Total_Deaths ,SUM(CAST(total_deaths as float))/SUM(total_cases)*100 as DeathPercentage
FROM PortifolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1, 2

SELECT *
FROM PortifolioProject..CovidDeaths dea
JOIN PortifolioProject..['covidVaccinations'] vac
 ON dea.location = vac.location
 AND dea.date = vac.date

--looking at Total Population vs Vaccinations 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortifolioProject..CovidDeaths dea
JOIN PortifolioProject..['covidVaccinations'] vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--Total vaccinations by rolling count
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(float, vac.new_vaccinations))OVER (PARTITION BY dea.location ORDER BY dea.location,
		dea.date) RollingPeopleVaccinated
FROM PortifolioProject..CovidDeaths dea
JOIN PortifolioProject..['covidVaccinations'] vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


--Population vs Vaccinated
--USING CTE
with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(float, vac.new_vaccinations))OVER (PARTITION BY dea.location ORDER BY dea.location,
		dea.date) RollingPeopleVaccinated
FROM PortifolioProject..CovidDeaths dea
JOIN PortifolioProject..['covidVaccinations'] vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population) * 100 
FROM PopvsVac

--USING TEMP TABLE
DROP TABLE IF EXISTS PercentPopulationVaccinated
CREATE TABLE PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(float, vac.new_vaccinations))OVER (PARTITION BY dea.location ORDER BY dea.location,
		dea.date) RollingPeopleVaccinated
FROM PortifolioProject..CovidDeaths dea
JOIN PortifolioProject..['covidVaccinations'] vac
 ON dea.location = vac.location
 AND dea.date = vac.date

 SELECT *, (RollingPeopleVaccinated/population) * 100 
FROM PercentPopulationVaccinated

--CREATING VIEW TO STORE DATA FOR LATER VISUALIZATION
CREATE VIEW PercentPopulationVaccinatedView AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(float, vac.new_vaccinations))OVER (PARTITION BY dea.location ORDER BY dea.location,
		dea.date) RollingPeopleVaccinated
FROM PortifolioProject..CovidDeaths dea
JOIN PortifolioProject..['covidVaccinations'] vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

CREATE VIEW DeathPercentView AS
SELECT Date, SUM(total_cases) Total_Cases, SUM(CAST(total_deaths as float)) as
Total_Deaths ,SUM(CAST(total_deaths as float))/SUM(total_cases)*100 as DeathPercentage
FROM PortifolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date

