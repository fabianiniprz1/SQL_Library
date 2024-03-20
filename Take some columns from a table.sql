/*
 * Date: 26/2/2024
 *
 * Overall: this code dynamically selects a subset of columns based on a reference column name 
 * 			and then retrieves those specific columns from the target table.
 * 
 * Instrutions: 
 * 			- Asigne your table name to the table_name variable
 * 			- Asigne the column name that you want to split your table (the code will only take the columns before the split column)
 * 
 * Data Engineer: 	Fabian Benavides
 * email: 			fabianiniprz@icloud.com
 * github: 			https://github.com/fabianiniprz1
 * linkedin: 		https://www.linkedin.com/in/fabian-andres-benavides-labiano-3980bb48/
 * 
 * */

-- Declare variables
declare 
	@table_name		varchar(500), -- Name of the table to process
	@split_column	varchar(500), -- Column name used for splitting
	@Columns 		varchar(8000) -- String to hold comma-separated column list

-- Set variable values (replace with actual values)
set @table_name		= 'your_table_name'
set @split_column	= 'your_column_name'

-- Check if temporary table exists and drop it if necessary
if exists (select 1 from tempdb.sys.objects where name like '##Column_names%')
begin
	drop table ##Column_names; -- Drop temporary table ##Column_names
end

-- Select column names and positions into a temporary table
select
	COLUMN_NAME,
	ORDINAL_POSITION
into
	##Column_names
from
	INFORMATION_SCHEMA.COLUMNS c
where
	TABLE_NAME = @table_name
	and
ORDINAL_POSITION <
(
	select
		min(ORDINAL_POSITION)
	from
		INFORMATION_SCHEMA.COLUMNS c
	where
		TABLE_NAME = @table_name
		and lower(COLUMN_NAME) like lower(@split_column)
);

-- Build a comma-separated list of quoted column names from the temporary table
set
	@Columns = (
	select
		'"' + COLUMN_NAME + '",', -- Concatenate double quotes and column name with a comma
	from
		##Column_names for xml path (''))

-- Remove the trailing comma from the list
set
	@Columns = (
	select
		left(@Columns, LEN(@Columns) - 1));

-- Replace "&amp;" with "&" to avoid encoding issues
set
	@Columns = replace(@Columns, '&amp;', '&');

-- Dynamically execute a select query with the built column list
exec ('select ' + @Columns + ' from ' + @table_name);
