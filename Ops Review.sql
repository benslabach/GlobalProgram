

--------------------------------------------------------------------------------
--------------------------Exits & Exit Reasons----------------------------------
--------------------------------------------------------------------------------

DROP TABLE those_exits_though IF EXISTS;

----------------------------
----Create Base Data Set----
----------------------------



---EOM Table (January 1, 2017 to Present)
CREATE TEMP TABLE those_exits_though AS (
SELECT 
 'Salesforce' as Source
, hist_bens.historizedmonthkey as Snapshot_Month
, hist_bens.historizedmonthkey + 100 as End_Month
, hist_bens.CEM__SPONSORSHIP_BENEFICIARY__CEM_ID as Global_ID
, hist_bens.CEM__SPONSORSHIP_BENEFICIARY__LOCAL_BENEFICIARY_ID as Local_Ben_ID
, hist_bens.CEM__ICP__CODE as FCP_ID
, natl.Region_Abbrev as Region
, natl.national_office_name as national_office
, natl.country_name as country
, hist_bens.BENEFICIARYNAME as Ben_Name
, hist_bens.BENEFICIARYBIRTHDATE as Birth_Date
, hist_bens.BENEFICIARYGENDER as Gender
, hist_bens.ISSPONSORED as Sponsored_Status
, exits.DATE_OF_ACTION__C as Exit_Date
, exits.EVENT_TYPE__C as Exit_Type
, exits.STATUS__C as Exit_Status
, exits.REASON_FOR_REQUEST__C as Exit_Reason
, EXTRACT (DAY FROM Exit_Date - Birth_Date) / 365.25 as Age_at_Exit
, FLOOR (Age_at_Exit) as Age_at_Exit_Floor
, EXTRACT (DAY FROM hist_bens.PIT - Birth_Date) / 365.25 as Age_at_Snapshot
, FLOOR (Age_at_Snapshot) as Age_at_Snapshot_Floor
, EXTRACT (DAY FROM current_date - Birth_Date) / 365.25 as Age_Current
, FLOOR (Age_Current) as Age_Current_Floor
, EXTRACT (DAY FROM ADD_MONTHS (hist_bens.PIT,6) - Birth_Date) / 365.25 as Age_at_Mid_Year
, FLOOR (Age_at_Mid_Year) as Age_at_Mid_Year_Floor
, CASE WHEN Exit_Date is null then Age_at_Mid_Year_Floor else Age_at_Exit_Floor end as "Age"

 FROM BENEFICIARY_SPONSORSHIP_EOM hist_bens ---All Active Beneficiaries as of a Given Date
 	INNER JOIN
	bslabach.NATIONAL_OFFICES natl  --Group by Country
	on hist_bens.CEM__FIELD_OFFICE__NAME = natl.national_office_name
 	INNER JOIN 
 	ADMIN.CI_SF_ACCOUNT account  --Join Account Table to Access BLE Table
	ON hist_bens.CEM__SPONSORSHIP_BENEFICIARY__CEM_ID = account.GLOBAL_NUMBER__C  
 		LEFT OUTER JOIN ADMIN.CI_SF_BENEFICIARY_LIFECYCLE_EVENT__C exits  ---BLE (Exit) Table
 		ON account.ID = exits.BENEFICIARY__C
		AND exits.EVENT_TYPE__C like ('%Exit%')
 		AND exits.DATE_OF_ACTION__C between hist_bens.PIT and ADD_MONTHS (hist_bens.PIT, 12)  --Exits Over the Following Year
		AND exits.STATUS__C = 'Closed' --Only use exits that are 'Closed' (have been completed, are not waiting on approval, etc.)
		
 WHERE 
 hist_bens.CEM__SPONSORSHIP_BENEFICIARY__BENEFICIARY_STATUS = 'Active'
 AND Country <> 'India' --exclude India
 AND FCP_ID not like '%0980' --exclude LDP children
 GROUP BY Source, Snapshot_Month, End_Month, Global_ID, Local_Ben_ID, FCP_ID, Region, national_office, country, Ben_Name, Birth_Date, Gender, Sponsored_Status, Exit_Date, Exit_Type, Exit_Status, Exit_Reason, Age_at_Exit,
 Age_at_Exit_Floor, Age_at_Snapshot, Age_at_Snapshot_Floor, Age_Current, Age_Current_Floor, Age_at_Mid_Year, Age_at_Mid_Year_Floor, "Age"
 )
;




---COMPASS Data (January 2014 to December 2016) 
INSERT INTO those_exits_though
select
'Compass' as Source
, compass.historizedmonthkey as Snapshot_Month
, compass.historizedmonthkey + 100 as End_Month
, account.GLOBAL_NUMBER__C as Global_ID
, account.LOCAL_BENEFICIARY_ID__C as Local_Ben_ID
, account.BENEFICIARY_ICP_ID__C as FCP_ID
, natl.Region_Abbrev as Region
, natl.national_office_name as national_office
, natl.country_name as country
, compass.COMPASS_PTCPNAME as Ben_Name
, account.PERSONBIRTHDATE as Birth_Date
, account.GENDER__C as Gender
, compass.ISSPONSORED as Sponsored_Status
, exits.DATE_OF_ACTION__C as Exit_Date
, exits.EVENT_TYPE__C as Exit_Type
, exits.STATUS__C as Exit_Status
, exits.REASON_FOR_REQUEST__C as Exit_Reason
, EXTRACT (DAY FROM Exit_Date - Birth_Date) / 365.25 as Age_at_Exit
, FLOOR (Age_at_Exit) as Age_at_Exit_Floor
, EXTRACT (DAY FROM compass.PIT - Birth_Date) / 365.25 as Age_at_Snapshot
, FLOOR (Age_at_Snapshot) as Age_at_Snapshot_Floor
, EXTRACT (DAY FROM current_date - Birth_Date) / 365.25 as Age_Current
, FLOOR (Age_Current) as Age_Current_Floor
, EXTRACT (DAY FROM ADD_MONTHS (compass.PIT,6) - Birth_Date) / 365.25 as Age_at_Mid_Year
, FLOOR (Age_at_Mid_Year) as Age_at_Mid_Year_Floor
, CASE WHEN Exit_Date is null then Age_at_Mid_Year_Floor else Age_at_Exit_Floor end as "Age"

from ADMIN.DVL_HISTORIZEDCDSPENDOFMONTHATMONTHEND compass
--JOIN ADMIN.NEED AS b on a.COMPASS_NEEDPTCP_ID = b.need_id
JOIN ADMIN.PTCP AS c on compass.LASTPTCP_ID = c.PTCP_ID
JOIN CI_SF_ACCOUNT account on account.COMPASS_ID__C = c.child_id 
INNER JOIN
	bslabach.NATIONAL_OFFICES natl  --Group by Country
	on account.FO__C = natl.national_office_name
 		LEFT OUTER JOIN ADMIN.CI_SF_BENEFICIARY_LIFECYCLE_EVENT__C exits  ---BLE (Exit) Table
 		ON account.ID = exits.BENEFICIARY__C
		AND exits.EVENT_TYPE__C like ('%Exit%')
 		AND exits.DATE_OF_ACTION__C between compass.PIT and ADD_MONTHS (compass.PIT, 12)  --Exits Over the Following Year
		AND exits.STATUS__C = 'Closed' --Only use exits that are 'Closed' (have been completed, are not waiting on approval, etc.)
where compass.ISREGISTERED = 1
 AND Country <> 'India' --exclude India
 AND FCP_ID not like '%0980' --exclude LDP children
 GROUP BY Source, Snapshot_Month, End_Month, Global_ID, Local_Ben_ID, FCP_ID, Region, national_office, country, Ben_Name, Birth_Date, Gender, Sponsored_Status, Exit_Date, Exit_Type, Exit_Status, Exit_Reason, Age_at_Exit,
 Age_at_Exit_Floor, Age_at_Snapshot, Age_at_Snapshot_Floor, Age_Current, Age_Current_Floor, Age_at_Mid_Year, Age_at_Mid_Year_Floor, "Age"
;



-------------------------
----Remove Duplicates----
-------------------------

--Check for Duplicates-- (Duplicates occur when a child is exited twice, often due to reinstatement)
SELECT * FROM those_exits_though WHERE (global_id, Snapshot_Month) in (SELECT global_id, Snapshot_Month FROM those_exits_though GROUP BY 1,2 HAVING count (*) > 1);


--Delete Duplicates---

--Delete all but the max exit date for each child
DELETE FROM those_exits_though 
WHERE (Snapshot_Month, Global_ID, Exit_Date) in 
(
SELECT a.Snapshot_Month, a.Global_ID, a.Exit_Date
FROM those_exits_though a
WHERE (Global_ID, Snapshot_Month) in (SELECT Global_ID, Snapshot_Month FROM those_exits_though GROUP BY 1,2 HAVING COUNT (*) > 1)
and 
(Global_ID, Snapshot_Month, Exit_Date) not in (
SELECT Global_ID, Snapshot_Month, MAX(Exit_Date) FROM those_exits_though 
WHERE (Global_ID, Snapshot_Month) in (SELECT Global_ID, Snapshot_Month FROM those_exits_though GROUP BY 1,2 HAVING COUNT (*) > 1)
GROUP BY 1,2) )
;

--Delete one-off beneficiary with two exits on the same day
DELETE FROM those_exits_though where Global_ID in ('06628040', '05760146', '05687876', '04693129', '04665846', '04665850', '05669388')and Exit_Type = 'Planned Exit'
;


--Check for Duplicates Again--
SELECT * FROM those_exits_though WHERE (global_id, Snapshot_Month) in (SELECT global_id, Snapshot_Month FROM those_exits_though GROUP BY 1,2 HAVING count (*) > 1) order by 4,2, exit_type, sponsored_status


---**SOME DUPLICATES STILL NEED CLEANING UP FOR THE COMPASS DATA----***




/*
----Data Discrepancy Between STATS Dashboard and EOM Tables-----

select "Date",  sum(EOM_Table) EOM_Table, Sum(Stats_Dashboard) Stats_Dashboard, sum(ABSOLUTE_DIFFERENCE) Absolute_Difference
from
(
select historizedmonthkey as "Date",a.CEM__FIELD_OFFICE__NAME, sum(case when CEM__SPONSORSHIP_BENEFICIARY__BENEFICIARY_STATUS = 'Active' then 1 else 0 end) EOM_Table,
"Value" as Stats_Dashboard, EOM_Table - Stats_Dashboard Difference, Abs(Difference) as Absolute_Difference
from BENEFICIARY_SPONSORSHIP_EOM a
INNER JOIN GlobalProgram_Metrics_VW b
ON a.CEM__FIELD_OFFICE__NAME = b."Field_Office"
AND a.HISTORIZEDMONTHKEY = extract (year from b."Date") ||''|| Case when substr(extract(month from b."Date"),1,1) < 10 then '0' else '' end ||''|| extract(month from b."Date")
where a.CEM__FIELD_OFFICE__NAME NOT IN ('East India', 'India')
AND a.CEM__ICP__CODE not like '%0980' --Remove LDP
AND b."Reporting_Frequency" = 'Monthly'
AND b."Measure" = 'Total Registered Sponsorship Beneficiaries'
group by 1,2,4
) c
group by 1
order by 1
*/








-------------------------------------------------------------------------------------------
---------------------------------------------OUTPUT----------------------------------------
-------------------------------------------------------------------------------------------


---Exits---
Select Country, "Age",
count(global_id) begin_beneficiary_count,
sum(case when exit_date is not null then 1 else 0 end) beneficiary_exits, beneficiary_exits / begin_beneficiary_count as Exit_Rate
from those_exits_though
where Snapshot_Month = '201808'
group by 1,2
order by 1,2
;

---Exit Reasons--- 
Select Region, Country, "Age", Exit_Reason,
count(global_id) beneficiary_exits
--sum(case when exit_date is not null then 1 else 0 end) beneficiary_exits, beneficiary_exits / begin_beneficiary_count as Exit_Rate
from those_exits_though
where Exit_reason is not null
AND Snapshot_Month = '201808'
group by 1,2,3,4
order by 1,2,3,4
;

---Current Ages---
Select Country, Age_at_Snapshot_Floor, count(global_id), sum(case when SPONSORED_STATUS = 0 then 1 else 0 end) Unsponsored
from those_exits_though
where Snapshot_Month = '201907'
group by 1,2
order by 1,2
;

--Youth Percentage---
select Snapshot_Month, sum(case when age_at_snapshot_floor < 12 then 1 else 0 end) as Children,
sum(case when age_at_snapshot_floor >= 12 then 1 else 0 end) as Youth,
count(*) as total_children,
Children / total_children as percent_children,
Youth / total_children as percent_youth
from those_exits_though
group by 1
order by 1
;


--Youth Exit Reasons by Country- They Fired Us ----
Select 
Snapshot_Month, end_month, country,
sum(case when exit_reason in ('Beneficiary / Caregiver Not Comply With Policies',
  'Unjustified Absence More Than 2 Months',
    'Conflicts With School Or Work Schedule',
       'Sponsored By Another Organization',
      'Beneficiary Pursuing Career Opportunity',
   'Family No Longer Interested in Program')
then 1 else 0 end) as they_fired_us,
count(*) as total_exits,
they_fired_us / total_exits as percent_of_exits
from those_exits_though
where "Age" >= 12
and exit_type is not null
and end_month = '201908'
group by 1,2,3
order by percent_of_exits desc
;