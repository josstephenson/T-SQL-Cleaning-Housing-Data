/*

Joseph Stephenson
04/21/2026
Use SQL Server Management Studio to transform raw housing data into a clean format for analysis.
Techniques used: Self-Joins, Window Functions (ROW_NUMBER), CTEs, String Manipulation, CASE Statements.

Destructive updates are commented out to prevent accidental data loss.

*/


-- Standardize the Date Format

SELECT 
	SaleDate, 
	CONVERT(Date, SaleDate) 
		AS SaleDate_clean
FROM nhd;

 
-------------------------------------------------
-------- Alter and Update table data ------------
-------------------------------------------------

/*

ALTER TABLE nhd 
ADD SaleDateConverted Date;

UPDATE nhd 
SET SaleDateConverted = CONVERT(Date, SaleDate);

*/

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------




-- Populate missing Property Address data from duplicate ParcelIDs

SELECT 
	a.ParcelID, 
	a.PropertyAddress, 
	b.ParcelID, 
	b.PropertyAddress, 
	ISNULL(a.PropertyAddress, b.PropertyAddress) 
		AS PropertyAddress_clean
FROM nhd a

JOIN nhd b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID

WHERE a.PropertyAddress IS NULL
	AND b.PropertyAddress IS NOT NULL;

/*

The ISNULL(a, b) function checks if 'a' is null. If it is, replace it with the value from 'b'.

A self-join is performed on the same table (nhd) aliased as 'a' and 'b'.
The join condition matches rows with the same ParcelID but different UniqueIDs (finds different rows for the same ParcelID).

*/


-------------------------------------------------
-------- Table data update (destructive) --------
-------------------------------------------------

/*

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM nhd a
JOIN nhd b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL
	AND b.PropertyAddress IS NOT NULL;

*/

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------




-- Separate the PropertyAddress field into Street and City columns using string manipulation functions.

SELECT
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) 
		AS PropertyAddress_street,
	SUBSTRING(propertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) 
		AS PropertyAddress_city
FROM nhd;

/*

SUBSTRING extracts parts of the string
The 1 means start from the first character, and CHARINDEX finds the position of the comma within the string
The -1 is used to exclude the comma from the Street value.

The +1 is used to start extracting the City value immediately after the comma
The LEN function is used to get the total length of the PropertyAddress string, ensuring capture of everything after the comma for the City value.

*/


-- Separate the OwnerAddress field into Street, City, and State columns.
Select
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
		AS OwnerAddress_street,
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
		AS OwnerAddress_city,
	PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
		AS OwnerAddress_state
From nhd

-- The PARSENAME function is typically used to parse object names in SQL Server via the dot (.) notation. 
-- REPLACE is used to substitute commas with dots in the string, allowing PARSENAME to extract the different parts (street, city, state) of the OwnerAddress.


-------------------------------------------------
-------- Alter and Update table data ------------
-------------------------------------------------

/*

ALTER TABLE nhd
Add 
PropertyAddress_street Nvarchar(255), 
PropertyAddress_city Nvarchar(255),
OwnerAddress_street Nvarchar(255),
OwnerAddress_city Nvarchar(255),
OwnerAddress_state Nvarchar(255);

UPDATE nhd
SET 
PropertyAddress_street = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1),
PropertyAddress_city = SUBSTRING(propertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)),
OwnerAddress_street = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3),
OwnerAddress_city = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2),
OwnerAddress_state = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

WHERE PropertyAddress IS NOT NULL
	AND OwnerAddress IS NOT NULL
	AND CHARINDEX(',', PropertyAddress) > 0;

*/

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------

-- Looking for inconsistent values for SoldAsVacant

SELECT 
    SoldAsVacant, 
    COUNT(SoldAsVacant) AS Value_Count
FROM nhd
GROUP BY SoldAsVacant
ORDER BY Value_Count DESC;


-- Use CASE statements to standardize the values in the SoldAsVacant column for better readability and consistency.

SELECT 
	SoldAsVacant,
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END as SoldAsVacant_clean
FROM nhd;


-------------------------------------------------
-------- Table data update (destructive) --------
-------------------------------------------------

/*

UPDATE nhd
SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
	END;

*/

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------




-- Find Duplicates using CTE and Window functions

WITH RowNumCTE AS (
    SELECT 
        *, 
        ROW_NUMBER() OVER (
            PARTITION BY 
                ParcelID, 
                PropertyAddress,
                SalePrice,
                SaleDate,
                LegalReference
            ORDER BY UniqueID
        ) AS RowNum
    FROM nhd
)
-- The ROW_NUMBER() function assigns a unique integer to rows within a partition.
-- The first occurrence of each partition (group of the specified columns) will have RowNum = 1, indicating the original record.
-- Further duplicates will have RowNum > 1.

SELECT *
FROM RowNumCTE
WHERE RowNum = 1;


-------------------------------------------------
-------- Table data update (destructive) --------
-------------------------------------------------

/*

DELETE
FROM RowNumCTE
WHERE RowNum > 1;

*/

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------




-- Delete Unused Columns

/*

After cleaning and transforming data, we may find that certain columns are no longer necessary for analysis. 
Removing these columns can help streamline the dataset and improve query performance.
This is merely a demonstration of how to drop columns that are no longer needed after the cleaning process.

*/
-------------------------------------------------
-------- Alter table data (destructive) ---------
-------------------------------------------------

/*

ALTER TABLE nhd
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

*/

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------



-- Standardize the Acreage field by rounding to 2 decimal places for consistency.

SELECT Acreage, ROUND(Acreage, 2) AS Acreage_clean
FROM nhd;


-------------------------------------------------
-------- Table data update (destructive) --------
-------------------------------------------------

/*

UPDATE nhd 
SET Acreage = ROUND(Acreage, 2);

*/

-------------------------------------------------
-------------------------------------------------
-------------------------------------------------