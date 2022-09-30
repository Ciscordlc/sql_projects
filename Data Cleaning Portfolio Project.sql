USE PortfolioProject

SELECT *
FROM PortfolioProject..NashvilleHousing;


-- Removing the time stamp from the SaleDate column
SELECT SaleDate, 
	   CONVERT(date, SaleDate) AS SaleDateConverted
FROM PortfolioProject..NashvilleHousing;


ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;


UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(Date, SaleDate);


-- Populating NULL Property Address Data
SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL
ORDER BY ParcelID;


SELECT a.ParcelID, 
	   a.PropertyAddress, 
	   b.ParcelID, 
	   b.PropertyAddress, 
	   ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
ON a.ParcelID = b.ParcelID AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL;


-- Separating Property and Owner Addresses into Individual Columns (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing;


SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS Address, 
	   SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing;


ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255), 
	PropertySplitCity Nvarchar(255);


UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1), 
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
FROM PortfolioProject..NashvilleHousing;


SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address, 
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City, 
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM PortfolioProject..NashvilleHousing;


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255), 
	OwnerSplitCity Nvarchar(255), 
	OwnerSplitState Nvarchar(255);


UPDATE PortfolioProject..NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), 
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), 
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);


-- Changing Y and N to Yes and No, respectively, in "Sold as Vacant" field
SELECT DISTINCT(SoldAsVacant), 
	   Count(SoldAsVacant) AS Count
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2;


SELECT SoldAsVacant, 
	   CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
			WHEN SoldAsVacant = 'N' THEN 'No'
			ELSE SoldAsVacant
			END AS UpdatedSoldAsVacant
FROM PortfolioProject..NashvilleHousing;


UPDATE PortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
						WHEN SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END;


SELECT COUNT(SoldAsVacant) AS SoldAsVacantCount
FROM PortfolioProject..NashvilleHousing
WHERE SoldAsVacant = 'Y' OR SoldAsVacant = 'N';


--Removing duplicates
WITH RowNumCTE AS (
	SELECT *, 
		   ROW_NUMBER() OVER (
				PARTITION BY ParcelID,
							 PropertyAddress,
							 SalePrice,
							 SaleDate,
							 LegalReference
				ORDER BY UniqueID
		   ) AS RowNum
	FROM PortfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE RowNum > 1
ORDER BY PropertyAddress;


WITH RowNumCTE AS (
	SELECT *, 
		   ROW_NUMBER() OVER (
				PARTITION BY ParcelID,
							 PropertyAddress,
							 SalePrice,
							 SaleDate,
							 LegalReference
				ORDER BY UniqueID
		   ) AS RowNum
	FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE RowNum > 1;


-- Delete unused columns
SELECT *
FROM PortfolioProject..NashvilleHousing;

ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN OwnerAddress,
			TaxDistrict,
			PropertyAddress,
			SaleDate