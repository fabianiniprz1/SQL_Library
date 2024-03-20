/*
 * Date: 19/03/2024
 *
 * Overall: this code utilizes temporary storage and a recursive approach to efficiently build a hierarchical structure 
 * 			of active employees and their corresponding boss emails.
 * 
 * Instrutions: 
 * 			- To use this code you must change next parameters:
 *	 			date				-> the date you use to join your table
 * 				employee_id			-> the name of your employee ID column
 * 				boss_id				-> the name of your boss ID column
 * 				boss_email			-> the name of your boss email column
 * 				public.your_table	-> the name of your table, and also your schema in case you don't use public
 * 
 * Data Engineer: 	Fabian Benavides
 * email: 			fabianiniprz@icloud.com
 * github: 			https://github.com/fabianiniprz1
 * linkedin: 		https://www.linkedin.com/in/fabian-andres-benavides-labiano-3980bb48/
 * 
 * */



-- Start by ensuring a clean slate for temporary data:

DROP TABLE IF EXISTS temp_your_table;  -- Remove any existing temporary table to avoid conflicts

-- Create a temporary table to hold employee and boss information:

CREATE TEMP TABLE temp_your_table (
    date date,         -- Date associated with the employee and boss relationship
    employee_id int,   -- ID of the employee
    boss_id int,       -- ID of the employee's boss
    boss_email varchar(200)  -- Email address of the boss
);

-- Populate the temporary table with relevant data from the main table:

INSERT INTO temp_your_table (
    date,
    employee_id,
    boss_id,
    boss_email
)
SELECT
    e.date,
    CAST(e.employee_id AS int) AS employee_id,  -- Ensure employee_id is an integer
    CAST(e.boss_id AS int) AS boss_id,         -- Ensure boss_id is an integer
    l.email AS boss_email
FROM
    public.your_table e
LEFT JOIN
    public.your_table l
ON
    l.employee_id = e.boss_id AND l.date = e.date  -- Join to find boss information
WHERE
    l.date = current_date AND l.status = 'Active';  -- Filter for current and active employees

-- Build a hierarchical structure of employees and their bosses:

WITH RECURSIVE row_level (  -- Define a recursive CTE (Common Table Expression)
    date,
    employee_id,
    boss_id,
    boss_email
) AS (
SELECT
    e.date,
    e.employee_id,
    e.boss_id,
    e.boss_email
FROM
    temp_your_table e
UNION ALL
SELECT
    l2.date,
    l2.employee_id,
    l2.boss_id,
    k.boss_email
FROM
    temp_your_table l2
INNER JOIN
    row_level k ON l2.boss_id = k.employee_id  -- Recursively join to build the hierarchy
)

-- Finally, retrieve the desired employee and boss email data:

SELECT
    k.employee_id,
    k.boss_email
FROM
    row_level k
