-- Use to create new folder in the Dataview hierarchy
Insert into DataViewFolders (FolderID, Name)
Values (100, 'CLC DataViews');

-- Confirm that your folder is in there
Select *
From DataViewFolders;

-- Open any working Dataview and save it as a copy. You'll use the new copy as the base and overwrite its values.
-- This update is the core of the Dataview, but all it really is is a big SQL query
-- Just with alot of extra hoops to jump through
-- Also, in order to be sure you see the changes in the dataview,
-- you have to disable the DataView > Options > List Settings > Save Custom Settings On Close

Update DataViews
SET 
	-- This is the Select portion
	-- Be sure to Delete the Select Statement
	-- And only us 'as' - LabTech doesn't like AS/As/aS, even though they are all valid MySQL
	FieldList = 'Computers.ComputerID,Computers.Name as `ComputerName`,Computers.ClientID,Computers.OS,Clients.Name as `ClientName`',
	-- Be sure to use the actual names and not assume
	-- Also, spaces after commas are not allowed!
	-- Actually just no spaces at all
	ColumnList = 'ComputerID,ComputerName,ClientID,OS,ClientName',
	-- Default sorting column
	SortField = '',
-- 	SortField = 'FailedLoginsUnique desc',
	-- Needs FROM in Body
	SQLBody = 'From Computers Left Join Clients on Computers.ClientID = Clients.ClientID',
	-- Still not really sure what this does,
	-- But make sure it's in SQL syntax, not simile syntax ('as')
	IDColumn = 'Computers.ComputerID',
	-- See previous comment
	ClientLink = 'Computers.ComputerID',
	-- For the love of everything good and holy, please overwrite your Where statement.
	-- otherwise you just comment out the previous 'where' and it doesnt change the code, since this is just a SQL Update
	-- this is where 80% of errors occur (the code will be clean, but the database sees old data, which gives incorrect results)
	SQLWhere = '',
-- 	SQLWhere = 'w_EventLogFailedLogin24Hour.TimeLogged > date_sub(current_time(), interval 24 hour)'

	-- Basically the Where statement works fine but you'll comment it out and think to yourself that you took out the where condition
	-- but you didnt, you just commented out the change. It's still there. So overwrite it please.

	-- In case you need to update the ID or Name of the dataview
-- 	DataViews.DataViewID = 12013
 	DataViews.Name = 'CLC - Example View'

-- If you have SQL IDs turned on in LT, finding the ID to overwrite is really easy.
WHERE DataViews.Name = 'CLC - Example View'
	-- Redunduncy for reducdancy's sake
	-- (but also please don't overwrite the wrong thing on accident)
	-- #realReasonsForRedundacy #thisIsWhyWeHaveTwoConsiditions
	And DataViews.DataViewID = 12020;

-- And to confirm everything in the DB or for troubleshooting.
Select *
From Dataviews
Where DataViews.DataViewID = 12020;