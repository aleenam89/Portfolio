--Data creation

CREATE TABLE CovidDeaths (
	iso_code CHAR(20),
	continent CHAR (20),
	location CHAR(100),
	date DATE,
	population FLOAT8,
	total_cases FLOAT8,
	new_cases FLOAT8,
	new_cases_smoothed FLOAT8,
	total_deaths FLOAT8,
	new_deaths FLOAT8,
	new_deaths_smoothed FLOAT8,
	total_cases_per_million FLOAT8,
	new_cases_per_million FLOAT8,
	new_cases_smoothed_per_million FLOAT8,
	total_deaths_per_million FLOAT8,
	new_deaths_per_million FLOAT8,
	new_deaths_smoothed_per_million FLOAT8,
	reproduction_rate FLOAT8,
	icu_patients FLOAT8,
	icu_patients_per_million FLOAT8,
	hosp_patients FLOAT8,
	hosp_patients_per_million FLOAT8,
	weekly_icu_admissions FLOAT8,
	weekly_icu_admissions_per_million FLOAT8,
	weekly_hosp_admissions FLOAT8,
	weekly_hosp_admissions_per_million FLOAT8
);

Select *
FROM CovidDeaths;

CREATE TABLE CovidVaccinations (
	iso_code CHAR(20),
	continent CHAR(20),
	location CHAR(100),
	date DATE,
	total_tests FLOAT8,
	new_tests FLOAT8,
	total_tests_per_thousand FLOAT8,
	new_tests_per_thousand FLOAT8,
	new_tests_smoothed FLOAT8,
	new_tests_smoothed_per_thousand FLOAT8,
	positive_rate FLOAT8,
	tests_per_case FLOAT8,
	tests_units	CHAR(50),
	total_vaccinations FLOAT8,
	people_vaccinated FLOAT8,
	people_fully_vaccinated FLOAT8,
	total_boosters FLOAT8,
	new_vaccinations FLOAT8,
	new_vaccinations_smoothed FLOAT8,
	total_vaccinations_per_hundred FLOAT8,
	people_vaccinated_per_hundred FLOAT8,
	people_fully_vaccinated_per_hundred	FLOAT8,
	total_boosters_per_hundred FLOAT8,
	new_vaccinations_smoothed_per_million FLOAT8,
	new_people_vaccinated_smoothed FLOAT8,
	new_people_vaccinated_smoothed_per_hundred FLOAT8,
	stringency_index FLOAT8,
	population_density FLOAT8,
	median_age FLOAT8,
	aged_65_older FLOAT8,
	aged_70_older FLOAT8,
	gdp_per_capita FLOAT8,
	extreme_poverty FLOAT8,
	cardiovasc_death_rate FLOAT8,
	diabetes_prevalence FLOAT8,
	female_smokers FLOAT8,
	male_smokers FLOAT8,
	handwashing_facilities FLOAT8,
	hospital_beds_per_thousand FLOAT8,
	life_expectancy FLOAT8,
	human_development_index FLOAT8,
	excess_mortality_cumulative_absolute FLOAT8,
	excess_mortality_cumulative	FLOAT8,
	excess_mortality FLOAT8,
	excess_mortality_cumulative_per_million FLOAT8
);

Select *
FROM CovidVaccinations;

--Data Exploration

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;

--Likelihood of dying from Covid
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage_by_case
FROM CovidDeaths
ORDER BY 1,2;

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage_by_case
FROM CovidDeaths
WHERE location like '%States%'
ORDER BY 1,2;

--total cases vs population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS case_percentage_by_population
FROM CovidDeaths
WHERE location like '%States%'
ORDER BY 1,2;

--Highest infection rate per population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population))*100 AS case_percentage_by_population
FROM CovidDeaths
GROUP BY location, population
ORDER BY case_percentage_by_population DESC;

--highest death count per population
SELECT location, MAX(total_deaths) AS total_death_count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- continents with highest death count
SELECT continent, MAX(total_deaths) AS total_death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

--global numbers

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

----

SELECT *
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3;

--With CTE
WITH PopvsVAC (continent, location, date, population, new_vaccinations, rolling_people_vaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVAC

--Temp Table

DROP TABLE IF EXISTS PercentPopVaccinated;

CREATE TABLE PercentPopVaccinated
	(Continent CHAR(20),
	 Location CHAR(100),
	 Date DATE,
	 Population FLOAT8,
	 new_vaccinations FLOAT8,
	 rolling_people_vaccinated FLOAT8
);

INSERT INTO PercentPopVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (rolling_people_vaccinated/population)*100
FROM PercentPopVaccinated

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ) AS rolling_people_vaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
