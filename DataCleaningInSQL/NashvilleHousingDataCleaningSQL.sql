/*

Nashville Housing Data Cleaning

*/

-- Select the top N rows to get column names
SELECT TOP 10 *
FROM Housing..NashvilleHousing

/* Column names: UniqueID, ParcelID, LandUse, PropertyAddress, SaleDate, SalePrice,
	LegalReference, SoldAsVacant, OwnerName, OwnerAddress, Acreage, TaxDistrict,
	LandValue, BuildingValue, TotalValue, YearBuilt, Bedrooms, FullBath, HalfBath

*/

-- Standardize date format
SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM Housing..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDate2 Date;

UPDATE NashvilleHousing
SET SaleDate2 = CONVERT(DATE, SaleDate)

SELECT SaleDate2
FROM Housing..NashvilleHousing

/* Just using UPDATE did not update the SaleDate column. 
	Needed to create a new column and then set it
*/

/* Populate Property Address data */

-- Checking to see for NULL values in PropertyAddress
SELECT *
FROM Housing..NashvilleHousing
WHERE PropertyAddress IS NULL

-- ParcelID is unique to property address. So can populate address if ParcelID matches
SELECT *
FROM Housing..NashvilleHousing
ORDER BY ParcelID

-- Joined the table to itself where the ParcelID is the same and UniqueID is different
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Housing..NashvilleHousing a
JOIN Housing..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Housing..NashvilleHousing a
JOIN Housing..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Checking to see for NULL values in PropertyAddress
SELECT *
FROM Housing..NashvilleHousing
WHERE PropertyAddress IS NULL

/* Breaking up Address into Individual Columns (Address, City, State) */

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM Housing..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE NashvilleHousing
ADD PropertySplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))

SELECT *
FROM Housing..NashvilleHousing

-- Owner Address Split

-- PARSENAME looks for period. So replace commas with period. Also, it returns split in reverse)
SELECT 
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS OwnerAddress
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS OwnerCity
, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS OwnerState
FROM Housing..NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

SELECT *
FROM Housing..NashvilleHousing

/* Change Y and N to Yes and No in "Sold as Vacant" field */

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Housing..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant)
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM Housing..NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END

/* Remove Duplicates */

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID, 
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
					) row_num
FROM Housing..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress


/* Delete unused columns */

SELECT *
FROM Housing..NashvilleHousing

ALTER TABLE Housing..NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE Housing..NashvilleHousing
DROP COLUMN SaleDate

