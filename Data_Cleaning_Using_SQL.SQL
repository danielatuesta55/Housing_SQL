-- SQL Cleaning Project 

-- Start by selecting all from the table 
SELECT * 
FROM ProjectPortfolio.dbo.NashvilleHousing;

-- Standarize sales data
-- Use the convert function first make sure that its doing what you want and then update the table
SELECT SaleDateConverted,
CONVERT(DATE, SaleDate)
FROM ProjectPortfolio.dbo.NashvilleHousing;

-- UPDATE the table 
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE,SaleDate);

-- ALTER TABLE
ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

-- UPDATE the table 
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(DATE,SaleDate); -- Now we have two date columns we can drop the old

--DROP Previouse column
ALTER TABLE NashvilleHousing
DROP COLUMN SaleDate;

-------------------------------------
-- Populate Property Address Data

--Check if there are null values in the column 
SELECT PropertyAddress
FROM ProjectPortfolio.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL;

--Since there are null values we can check the whole data source to try to find an explanation 
SELECT *
FROM ProjectPortfolio.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL;

-- We need a point of reference to populate the data so we can look at all the data ordered by ParcelID
SELECT * 
FROM NashvilleHousing
ORDER BY ParcelID;

-- We can see that parcel ID makes perfect reference for the property address 
-- populate with if 
--Self -join

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID,b.PropertyAddress
FROM  ProjectPortfolio.dbo.NashvilleHousing a
JOIN  ProjectPortfolio.dbo.NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ]<>b.[UniqueID ] -- This tells it to join but not where its the same row
WHERE a.PropertyAddress IS NULL; -- This will show us what we need to populate

-- Since we actually found that the property does have an address we will use the ISNULL function 

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID,b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM  ProjectPortfolio.dbo.NashvilleHousing a
JOIN  ProjectPortfolio.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ] -- This tells it to join but not where its the same row
WHERE a.PropertyAddress IS NULL; -- This will show us what we need to populate

-- use UPDATE, SET AND ISNULL to update and populate the column 
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM  ProjectPortfolio.dbo.NashvilleHousing a
JOIN  ProjectPortfolio.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;

---------------------------
-- Breaking out Adress into individual columns (address, city, state)
SELECT PropertyAddress
FROM NashvilleHousing;
-- Delimiter is a ,
--use index and subchar

SELECT 
SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress)-1) AS Address, -- -1 deletes the comma
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) as City 
FROM NashvilleHousing;

-- Alter table
ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

-- Update to put in the data 
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',', PropertyAddress)-1)

-- Alter table
ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

-- Update to put in the data 
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

-----------------------------------------------------------
-- Split the owner column address by using parcing 

SELECT OwnerAddress
FROM ProjectPortfolio.dbo.NashvilleHousing;

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'), 3),-- Parcing looks for periods so we need to replace commas with periods
PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
FROM ProjectPortfolio.dbo.NashvilleHousing;


-- Alter table
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

-- Update to put in the data 
UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3);

-- Alter table
ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

-- Update to put in the data 
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2);

GO
-- Alter table
ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);
GO
GO
-- Update to put in the data 
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1);
GO

-----
-- Change Y to yes and N to no on the SoldAsVacant column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS CountOfUniqueInputs
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;

-- since Yes and No have more values we will change all of them to the same syntax
-- uSING CASE STATEMENT
SELECT SoldAsVacant 
,CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
FROM NashvilleHousing

--Now that it works we use UPDATE STATEMENT 
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

------------------------------------------
--Remove duplicate data
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDateConverted,
				LegalReference
				ORDER BY
					UniqueID
					) row_num
FROM ProjectPortfolio.dbo.NashvilleHousing
)

-- Delete the 104 rows
SELECT *
FROM RowNumCTE
WHERE row_num > 1

-------------------------------

-- Delete some unused columns 

SELECT *
FROM NashvilleHousing; -- We identify the columns that we dont use. Normally we would only do this to views and not raw data

ALTER TABLE ProjectPortfolio.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;

