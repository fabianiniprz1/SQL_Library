/*
 * Date: 20/03/2024
 *
 * Overall: This code takes a table containing ticket information and extracts specific data related to questions, sections, failure reasons, and remarks. Here's a breakdown of its functionality:
 * 
 * 		1. **Setup and Initial Processing:**
 * 		   - It declares variables to store table names, column names, and SQL statements.
 * 		   - It sets the names of the table to process (`@table_name`) and a reference column (`@standard_column`) to identify sections.
 * 		   - It retrieves a list of column names and their ordinal positions (order within the table) for the specified table.
 * 		
 * 		2. **Identifying Question, Section, etc. Columns:**
 * 		   - It calculates the minimum and maximum ordinal positions likely containing question, section name, failure reason, and remarks columns based on their names (using LIKE operator).
 * 		   - It builds comma-separated lists of these columns using dynamic SQL, filtering out irrelevant ones.
 * 		
 * 		3. **Populating Temporary Tables:**
 * 		   - It uses dynamic SQL to unpivot the data from the main table. Unpivoting rearranges data from rows to columns, making it easier to work with specific question-answer pairs, sections, etc.
 * 		   - It populates temporary tables (`#Column_questions`, `#Column_sectionname`, etc.) with the unpivoted data, joining with the column names table for clarity.
 * 		
 * 		4. **Finding Section Start Positions:**
 * 		   - It identifies the ordinal position of the first section name column relative to question columns.
 * 		
 * 		5. **Building the Final Output Table:**
 * 		   - It builds a final table named `#final_table` containing the desired information:
 * 		     - Ticket number
 * 		     - Question
 * 		     - Answer (assuming one answer per question)
 * 		     - Section name (based on the identified position)
 * 		     - Failure reason (matched to the previous question)
 * 		     - Remark (matched to the question before the failure reason)
 * 		   - It uses LEFT JOINs to ensure all ticket information is included even if some sections or remarks are missing.
 * 		
 * 		In essence, this code restructures the data from the original table into a more organized format, focusing on questions, their answers, corresponding sections, potential failure reasons, and remarks. 
 * 
 * 
 * Instrutions: 
 * 			- To use this code you must change next parameters:
 *	 			QA_Table				-> the table where you have your quality data
 * 				Split_column_QA			-> the name of the column which indicate where the questions columns begin.
 * 
 * Data Engineer: 	Fabian Benavides
 * email: 			fabianiniprz@icloud.com
 * github: 			https://github.com/fabianiniprz1
 * linkedin: 		https://www.linkedin.com/in/fabian-andres-benavides-labiano-3980bb48/
 * 
 * */


-- Declare variables to hold table and column names, SQL statements, etc.
declare @table_name           varchar(500)  -- Name of the table to process
        ,@standard_column     varchar(500)  -- Reference column to identify section start

        ,@MIN                  int             -- Minimum ordinal position
        ,@MAX                  int             -- Maximum ordinal position

        ,@sql                 varchar(8000) -- String to hold dynamic SQL statements

        ,@Column_questions     varchar(8000) -- Comma-separated list of question columns
        ,@Column_sectionname   varchar(8000) -- Comma-separated list of section name columns
        ,@Column_failureReason varchar(8000) -- Comma-separated list of failure reason columns
        ,@Column_Remarks       varchar(8000) -- Comma-separated list of remark columns

-- Set the table and reference column names
SET @table_name = 'QA_Table'
SET @standard_column = 'Split_column_QA'

-- Check if temporary table #Column_names already exists and drop it if so
if OBJECT_ID('tempdb..#Column_names') is not null drop table #Column_names;

-- Get a list of column names and their ordinal positions from the table
select
    COLUMN_NAME
  , ORDINAL_POSITION
into
    #Column_names  -- Temporary table to store column information
from
    INFORMATION_SCHEMA.COLUMNS c
where
    TABLE_NAME = @table_name  -- Filter for the specified table
and
    ORDINAL_POSITION >=   -- Select columns starting from (including) the reference column
    (
        select
            ORDINAL_POSITION
        from
            INFORMATION_SCHEMA.COLUMNS c
        where
            TABLE_NAME = @table_name
            and COLUMN_NAME = @standard_column
    )

-- Find the minimum and maximum ordinal positions for question, section name, etc. columns
SET @MIN = ( SELECT min(ORDINAL_POSITION) FROM #Column_names WHERE COLUMN_name like '%sectionname%')
SET @MAX = ( SELECT max(ORDINAL_POSITION) from #Column_names WHERE COLUMN_name like '%Remarks%')

-- Build comma-separated lists of question, section name, etc. columns using dynamic SQL
set @Column_questions = (
    select
        '"' + COLUMN_NAME + '",'  -- Enclose each column name in double quotes
    from
        #Column_names
    where
        ORDINAL_POSITION between @MIN and @MAX  -- Select columns within the identified range
        and COLUMN_name not like '%sectionname%'  -- Exclude section name column
        and COLUMN_name not like '%ailureReason%' -- Exclude failure reason column
        and COLUMN_name not like '%emarks%'       -- Exclude remarks column
    for xml path (''))  -- Concatenate column names with comma separators

-- Similar logic for section name, failure reason, and remarks columns
set @Column_sectionname = (
    select
        '"' + COLUMN_NAME + '",'
    from
        #Column_names
    where
        ORDINAL_POSITION between @MIN and @MAX
        and COLUMN_name like '%sectionname%'
    for xml path (''))

set @Column_failureReason = (
    select
        '"' + COLUMN_NAME + '",'
    from
        #Column_names
    where
        ORDINAL_POSITION between @MIN and @MAX
        and COLUMN_name like '%ailureReason%'
    for xml path (''))

set @Column_Remarks = (
    select
        '"' + COLUMN_NAME + '",'
    from
        #Column_names
    where
        ORDINAL_POSITION between @MIN and @MAX
        and COLUMN_name like '%emarks%'
    for xml path (''))

-- Remove the trailing comma from each list
set @Column_questions 		= ( SELECT left(@Column_questions, LEN(@Column_questions) -1))
SET @Column_sectionname 	= ( SELECT left(@Column_sectionname, LEN(@Column_sectionname) -1))
SET @Column_failureReason 	= ( SELECT left(@Column_failureReason, LEN(@Column_failureReason) -1))
SET @Column_Remarks 		= ( SELECT left(@Column_Remarks, LEN(@Column_Remarks) -1))


-- Fix '&' character for proper XML processing
SET @Column_questions = replace(@Column_questions,'&amp;','&')  -- Replace '&amp;' with '&'

-- Drop temporary tables if they already exist (for cleanliness)
if OBJECT_ID('tempdb..#Column_questions') is not null drop table #Column_questions;

if OBJECT_ID('tempdb..#Column_sectionname') is not null drop table #Column_sectionname;

if OBJECT_ID('tempdb..#Column_failureReason') is not null drop table #Column_failureReason

if OBJECT_ID('tempdb..#Column_Remarks') is not null drop table #Column_Remarks;

if OBJECT_ID('tempdb..#column_ordinal_position_sectionName') is not null drop table #column_ordinal_position_sectionName;

-- Use dynamic SQL to populate temporary tables with un pivoted data
exec (
'select 
    a.*
  ,b.ORDINAL_POSITION
into 
    #Column_questions
from 
    (select 
        Ticket_Number
        ,' + @Column_questions +' 
      from ' 
        + @table_name + ') as p
    unpivot (answer for question in (' + @Column_questions + ')) as unpvt1) a
    inner join
        #Column_names b
    on a.question = b.COLUMN_NAME'  -- Join with column names table
)

-- Similar logic for section name, failure reason, and remarks using separate EXEC statements

exec (  -- For section names
'select 
    a.*
  ,b.ORDINAL_POSITION
into 
    #Column_sectionname
from 
    (select 
        Ticket_Number
        ,' +@Column_sectionname +' 
  from ' 
        + @table_name + ') as p
    unpivot (sectionname for section in (' + @Column_sectionname + ')) as unpvt2) a
  inner join
        #Column_names b
    on a.section = b.COLUMN_NAME'
)

-- Similar logic for failure reasons and remarks

-- Identify the ordinal position of the first section name column 
select
    distinct
    a.ORDINAL_POSITION
  ,max(b.ORDINAL_POSITION) ordinal_section_name
into
    #column_ordinal_position_sectionName
from
    #Column_questions a
inner join
    #Column_sectionname b
on
    a.ORDINAL_POSITION > b.ORDINAL_POSITION  -- Find sections following questions
group by
    a.ORDINAL_POSITION

-- Drop temporary table if it already exists
if OBJECT_ID('tempdb..#final_table') is not null drop table #final_table;

-- Build the final output table with questions, sections, failure reasons, and remarks
select
    distinct
    a.Ticket_Number
  ,a.question
  ,a.answer
  ,1 count_question  -- Assuming there's only one answer per question
  ,x.sectionname
  ,b.failureReason
  ,c.Remark
into
    #final_table  -- Final table holding processed data
from
    #Column_questions a
left join
    #column_ordinal_position_sectionName xtz  -- Join with section position info
on
    a.ORDINAL_POSITION = xtz.ORDINAL_POSITION
left join
    #Column_sectionname x  -- Join with section names table
on
    xtz.ordinal_section_name = x.ORDINAL_POSITION
left join
    #Column_failureReason b  -- Join with failure reasons table
on
    a.Ticket_Number = b.Ticket_Number
and a.ORDINAL_POSITION = (b.ORDINAL_POSITION)-1  -- Match failure reason to previous question
left join
    #Column_Remarks c  -- Join with remarks table
on
    a.Ticket_Number = c.Ticket_Number
and a.ORDINAL_POSITION = (c.ORDINAL_POSITION)-2  -- Match remark to the question before failure reason


select
	*
from
	#final_table
