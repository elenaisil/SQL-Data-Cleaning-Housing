-- ==============================================================================
-- DATA INGESTION
-- ==============================================================================
INSTALL spatial;
LOAD spatial;

-- Load the raw data from Excel
CREATE OR REPLACE TABLE raw_data AS
SELECT * FROM read_xlsx("C:/analytics/nashville_housing_project/Nashville-Housing-Data.xlsx");

-- ==============================================================================
-- CREATING CLEANED TABLE
-- ==============================================================================
-- DESIGN PHILOSOPHY & THOUGHT PROCESS:
-- 1. REPEATABILITY (Idempotency): Instead of using ALTER TABLE and UPDATE commands 
--    which can fail on re-runs, this script consolidates all transformations into a 
--    single CREATE OR REPLACE TABLE statement.
-- 2. DATA IMMUTABILITY: The 'raw_data' table remains completely untouched. All 
--    cleaning, splitting, and filling of missing values happen in this new layer.
-- 3. EFFICIENCY: Uses Window Functions (COALESCE + FIRST_VALUE) to populate missing 
--    addresses, eliminating the need for complex self-joins.
-- 4. DUPLICATE REMOVAL: Uses QUALIFY + ROW_NUMBER() to ensure only unique records 
--    are ingested into the final table.
-- ==============================================================================

CREATE OR REPLACE TABLE cleaned_housing_data AS
WITH PopulatedData AS (
    -- Window function for populating missing PropertyAddress based on ParcelID
    SELECT 
        *,
        COALESCE(
            PropertyAddress, 
            FIRST_VALUE(PropertyAddress IGNORE NULLS) OVER (PARTITION BY ParcelID ORDER BY UniqueID)
        ) AS CleanedPropertyAddress
    FROM raw_data
)
SELECT 
    -- 1. Original Columns (Excluding old PropertyAddress and SoldAsVacant to avoid duplicates)
    UniqueID,
    ParcelID,
    LandUse,
    SalePrice,
    LegalReference,
    OwnerName,
    Acreage,
    LandValue,
    BuildingValue,
    TotalValue,
    YearBuilt,
    Bedrooms,
    FullBath,
    HalfBath,
    TaxDistrict, 

    -- 2. Separating PropertyAddress into individual columns 
    -- (Using the newly populated 'CleanedPropertyAddress' and TRIM to remove extra spaces)
    TRIM(split_part(CleanedPropertyAddress, ',', 1)) AS PropertySplitAddress, 
    TRIM(split_part(CleanedPropertyAddress, ',', 2)) AS PropertySplitCity,
    
    -- 3. Separating OwnerAddress into individual columns 
    TRIM(split_part(OwnerAddress, ',', 1)) AS OwnerSplitAddress,
    TRIM(split_part(OwnerAddress, ',', 2)) AS OwnerSplitCity,
    TRIM(split_part(OwnerAddress, ',', 3)) AS OwnerSplitState,
    
    -- 4. Standardizing the date format to dd-mmm-YYYY
    strftime(CAST(SaleDate AS DATE), '%d-%b-%Y') AS SaleDateConverted,

    -- 5. Fixing inconsistency in the 'SoldAsVacant' column (Y/N -> Yes/No)
    CASE 
        WHEN UPPER(TRIM(SoldAsVacant)) = 'Y' THEN 'Yes'
        WHEN UPPER(TRIM(SoldAsVacant)) = 'N' THEN 'No'
        ELSE SoldAsVacant
    END AS SoldAsVacant
    
FROM PopulatedData

-- 6. Not including duplicates (Keeping only the first occurrence)
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY ParcelID, 
                 CleanedPropertyAddress,
                 SaleDate, 
                 SalePrice, 
                 LegalReference
    ORDER BY UniqueID
) = 1;