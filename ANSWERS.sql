-- ## Prescribers Database

-- For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File](https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.
-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT npi, total_claim_count
FROM prescription
JOIN prescriber USING(npi)
ORDER BY total_claim_count DESC;

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name, specialty_description, npi, total_claim_count
FROM prescription
JOIN prescriber USING(npi)
ORDER BY total_claim_count DESC;

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT p.specialty_description, SUM(pr.total_claim_count) AS total_claim_count
FROM prescriber p
JOIN prescription pr USING(npi)
GROUP BY p.specialty_description, pr.npi
ORDER BY total_claim_count DESC;

--     b. Which specialty had the most total number of claims for opioids?

SELECT p.specialty_description, SUM(pr.total_claim_count) AS total_claim_count
FROM prescriber AS p
JOIN prescription AS pr USING(npi)
JOIN drug AS dr USING(drug_name)
WHERE dr.opioid_drug_flag = 'Y'
GROUP BY p.specialty_description
ORDER BY total_claim_count DESC;

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT COUNT(specialty_description) AS count_spec_desc, p.specialty_description
FROM prescriber p
LEFT JOIN prescription pr USING(npi)
WHERE pr.npi IS NULL
GROUP BY p.specialty_description
ORDER BY count_spec_desc DESC;

--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

SELECT p.specialty_description,
SUM(pr.total_claim_count) AS total_claim_count,
SUM(CASE WHEN dr.opioid_drug_flag = 'Y' THEN pr.total_claim_count ELSE 0 END) AS opioid_claim_count,
ROUND((SUM(CASE WHEN dr.opioid_drug_flag = 'Y' THEN pr.total_claim_count ELSE 0 END) /
SUM(pr.total_claim_count)) * 100, 2) AS opioid_percentage
FROM prescriber p
JOIN prescription pr USING(npi)
JOIN drug dr USING(drug_name)
GROUP BY p.specialty_description
ORDER BY opioid_percentage DESC;

-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, total_drug_cost ::MONEY
FROM prescription AS pr
JOIN drug USING(drug_name)
ORDER BY total_drug_cost DESC
LIMIT 1;

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 

SELECT dr.drug_name, 
    CASE
        WHEN dr.opioid_drug_flag = 'Y' THEN 'Opioid'
        WHEN dr.antibiotic_drug_flag = 'Y' THEN 'Antibiotic'
        ELSE 'Neither'
    END AS drug_type
FROM prescription AS pr
JOIN drug AS dr 
USING (drug_name);

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT drug_type, SUM(total_drug_cost)::MONEY AS total_cost
FROM ( 
	SELECT 
        CASE
            WHEN dr.opioid_drug_flag = 'Y' THEN 'Opioid'
            WHEN dr.antibiotic_drug_flag = 'Y' THEN 'Antibiotic'
            ELSE 'Neither'
        END AS drug_type,
        pr.total_drug_cost
    FROM prescription AS pr
    JOIN drug AS dr USING (drug_name)
) AS drug_costs
WHERE drug_type IN ('Opioid', 'Antibiotic')
GROUP BY drug_type;

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT count(DISTINCT cbsa)
FROM cbsa
JOIN fips_county USING(fipscounty)
WHERE state = 'TN'

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsa.cbsaname, SUM(pop.population) AS combined_population
FROM cbsa
JOIN fips_county AS fips USING (fipscounty)
JOIN population AS pop USING (fipscounty)
GROUP BY cbsa.cbsaname
ORDER BY combined_population DESC;
	
--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT fips_county.county, population.population
FROM fips_county
JOIN population USING (fipscounty)
LEFT JOIN cbsa USING (fipscounty)
WHERE cbsa.cbsa IS NULL
ORDER BY population.population DESC
LIMIT 1;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT pn.drug_name, pn.total_claim_count,
    CASE WHEN dr.opioid_drug_flag = 'Y' THEN 'Opioid'
        ELSE 'Non_Opioid'
    END AS is_opioid
FROM prescription AS pn
JOIN drug AS dr USING (drug_name)
WHERE pn.total_claim_count >= 3000;

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT pr.nppes_provider_first_name AS first_name, pr.nppes_provider_last_org_name AS last_name, pn.drug_name, pn.total_claim_count,
    CASE WHEN dr.opioid_drug_flag = 'Y' THEN 'Opioid'
        ELSE 'Non_Opioid'
    END AS is_opioid
FROM prescription AS pn
JOIN drug AS dr USING (drug_name)
JOIN prescriber AS pr USING(npi)
WHERE pn.total_claim_count >= 3000;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y').
-- **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT pr.npi, dr.drug_name
FROM prescriber AS pr
CROSS JOIN drug AS dr 
WHERE pr.specialty_description = 'Pain Management' 
    AND pr.nppes_provider_city = 'NASHVILLE'
    AND dr.opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT pr.npi, dr.drug_name, total_claim_count
FROM prescriber AS pr
CROSS JOIN drug AS dr
LEFT JOIN prescription AS pn USING(npi)
WHERE pr.specialty_description = 'Pain Management' 
    AND pr.nppes_provider_city = 'NASHVILLE'
    AND dr.opioid_drug_flag = 'Y';

--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.


-- BONUS --

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(DISTINCT pr.npi) AS not_in_pn
FROM prescriber AS pr
LEFT JOIN prescription AS pn USING(npi)
WHERE pn.npi IS NULL;

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT dr.generic_name, COUNT(*) AS prescription_count
FROM prescriber AS pr
JOIN prescription AS pn ON pr.npi = pn.npi
JOIN drug AS dr ON pn.drug_name = dr.drug_name
WHERE pr.specialty_description = 'Family Practice'
GROUP BY dr.generic_name
ORDER BY prescription_count DESC
LIMIT 5;

--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
    
--     b. Now, report the same for Memphis.
    
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

-- 5.
--     a. Write a query that finds the total population of Tennessee.
    
--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

-- -- In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres. 

-- -- For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management Specialists compared to those from Pain Managment specialists.

-- -- 1. Write a query which returns the total number of claims for these two groups. Your output should look like this: 

-- -- specialty_description         |total_claims|
-- -- ------------------------------|------------|
-- -- Interventional Pain Management|       55906|
-- -- Pain Management               |       70853|

SELECT specialty_description, sum(total_claim_count) AS total_claims
FROM prescriber AS pr
JOIN prescription AS pn
ON pr.npi = pn.npi
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description
ORDER BY total_claims

-- -- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

-- specialty_description         |total_claims|
-- ------------------------------|------------|
--                               |      126759|
-- Interventional Pain Management|       55906|
-- Pain Management               |       70853|

SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber AS pr
JOIN prescription AS pn ON pr.npi = pn.npi
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description

UNION

SELECT '', SUM(total_claim_count) AS total_claims
FROM prescriber AS pr
JOIN prescription AS pn ON pr.npi = pn.npi
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')

-- 3. Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.

SELECT COALESCE(specialty_description, '') AS specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber AS pr
JOIN prescription AS pn ON pr.npi = pn.npi
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS ((specialty_description),());

-- 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:

-- specialty_description         |opioid_drug_flag|total_claims|
-- ------------------------------|----------------|------------|
--                               |                |      129726|
--                               |Y               |       76143|
--                               |N               |       53583|
-- Pain Management               |                |       72487|
-- Interventional Pain Management|                |       57239|

SELECT COALESCE(specialty_description, '') AS specialty_description, COALESCE(opioid_drug_flag, '') AS opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber AS pr
JOIN prescription AS pn ON pr.npi = pn.npi
JOIN drug as dr ON pn.drug_name = dr.drug_name
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS ((specialty_description),(opioid_drug_flag),())

-- 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?

SELECT COALESCE(specialty_description, '') AS specialty_description, COALESCE(opioid_drug_flag, '') AS opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber AS pr
JOIN prescription AS pn ON pr.npi = pn.npi
JOIN drug as dr ON pn.drug_name = dr.drug_name
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(opioid_drug_flag, specialty_description)

-- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?

SELECT COALESCE(specialty_description, '') AS specialty_description, COALESCE(opioid_drug_flag, '') AS opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber AS pr
JOIN prescription AS pn ON pr.npi = pn.npi
JOIN drug as dr ON pn.drug_name = dr.drug_name
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(specialty_description, opioid_drug_flag)

-- 7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?

SELECT COALESCE(specialty_description, '') AS specialty_description, COALESCE(opioid_drug_flag, '') AS opioid_drug_flag, SUM(total_claim_count) AS total_claims
FROM prescriber AS pr
JOIN prescription AS pn ON pr.npi = pn.npi
JOIN drug as dr ON pn.drug_name = dr.drug_name
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY CUBE(opioid_drug_flag, specialty_description)

-- 8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

-- The end result of this question should be a table formatted like this:

-- city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-- -----------|-------|--------|-----------|--------|---------|-----------|
-- CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
-- KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
-- MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
-- NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|

-- For this question, you should look into use the crosstab function, which is part of the tablefunc extension (https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) run the command
-- 	CREATE EXTENSION tablefunc;

-- Hint #1: First write a query which will label each drug in the drug table using the six categories listed above.
-- Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column.
-- Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.