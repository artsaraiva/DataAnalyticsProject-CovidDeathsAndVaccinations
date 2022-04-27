--viewing the data
SELECT location,
       date,
       total_cases,
       new_cases,
       total_deaths,
       population
FROM   portifolio_projects.dbo.covid_deaths
WHERE continent is not null
ORDER  BY location,
          date

--total cases x total deaths
SELECT location,
       date,
       total_cases,
       total_deaths,
       ( total_deaths / total_cases ) * 100 AS death_percent
FROM   portifolio_projects.dbo.covid_deaths
WHERE continent is not null
ORDER  BY location,
          date 

--total cases x population
SELECT location,
       date,
       total_cases,
       population,
       ( total_cases / population ) * 100 AS case_percentage
FROM   portifolio_projects.dbo.covid_deaths
WHERE continent is not null
ORDER  BY location,
          date 

--country with highest infection rate x population
SELECT location,
       population,
       MAX(total_cases) as highest_case_count,
	   MAX(( total_cases / population )) * 100 AS max_case_percentage
FROM   portifolio_projects.dbo.covid_deaths
WHERE continent is not null
GROUP  BY location,
		  population
ORDER  BY max_case_percentage DESC

--country with highest death count
SELECT location,
       MAX(CAST(total_deaths as INTEGER)) as highest_death_count
FROM   portifolio_projects.dbo.covid_deaths
WHERE continent is not null
GROUP  BY location
ORDER  BY highest_death_count DESC

--continent with highest death count
SELECT location,
       MAX(CAST(total_deaths AS INTEGER)) AS highest_death_count
FROM   portifolio_projects.dbo.covid_deaths
WHERE  continent IS NULL
       AND location IN ( 'North America', 'South America', 'Asia', 'Europe',
                         'Africa', 'Oceania' )
GROUP  BY location
ORDER  BY highest_death_count DESC 

--total cases x total deaths x death percent per day
SELECT date,
       SUM(new_cases) AS total_cases,
       SUM(Cast(new_deaths AS INTEGER)) AS total_deaths,
       (SUM(CAST(new_deaths AS INTEGER)) / SUM(new_cases)) * 100 AS death_percent
FROM   portifolio_projects.dbo.covid_deaths
WHERE  continent IS NOT NULL
GROUP  BY date
ORDER  BY 1,
          2 

--total numbers total
SELECT SUM(new_cases) AS total_cases,
       SUM(CAST(new_deaths AS INTEGER)) AS total_deaths,
       (SUM(CAST(new_deaths AS INTEGER)) / SUM(new_cases)) * 100 AS death_percent
FROM   portifolio_projects.dbo.covid_deaths
WHERE  continent IS NOT NULL
ORDER  BY 1,
          2 

--population x vaccination rate 
SELECT dea.continent,
       dea.location,
       dea.date,
       dea.population,
	   vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS BIGINT)) 
         OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS vaccination_cumulative
FROM    portifolio_projects.dbo.covid_vaccinations vac
        JOIN portifolio_projects.dbo.covid_deaths dea
         ON dea.location = vac.location
            AND vac.date = dea.date
WHERE  dea.continent IS NOT NULL
ORDER  BY dea.location,
          dea.date 

--CTE with vaccination percentage
WITH popxvac (continent, location, date, population, new_vaccinations, vaccination_cumulative)
     AS (SELECT dea.continent,
                dea.location,
                dea.date,
                dea.population,
                vac.new_vaccinations,
                Sum(CAST(vac.new_vaccinations AS BIGINT))
                  OVER (
                    partition BY dea.location
                    ORDER BY dea.location, dea.date) AS vaccination_cumulative
         FROM   portifolio_projects.dbo.covid_vaccinations vac
                JOIN portifolio_projects.dbo.covid_deaths dea
                  ON dea.location = vac.location
                     AND vac.date = dea.date
         WHERE  dea.continent IS NOT NULL)
SELECT *,
       ( vaccination_cumulative / population ) * 100 AS vaccination_percent
FROM   popxvac
ORDER  BY location,
          date 

--creating view for testing
CREATE VIEW vaccination_rate_per_population
AS
  SELECT dea.continent,
         dea.location,
         dea.date,
         dea.population,
         vac.new_vaccinations,
         Sum(Cast(vac.new_vaccinations AS BIGINT))
           OVER (
             partition BY dea.location
             ORDER BY dea.location, dea.date) AS vaccination_cumulative
  FROM   portifolio_projects.dbo.covid_vaccinations vac
         JOIN portifolio_projects.dbo.covid_deaths dea
           ON dea.location = vac.location
              AND vac.date = dea.date
  WHERE  dea.continent IS NOT NULL 

SELECT * FROM vaccination_rate_per_population