# Nashville Housing - SQL Data Cleaning Project

## 📌 Project Overview
This project focuses on cleaning and standardizing a raw real estate dataset (Nashville Housing) using **DuckDB** and **SQL**. The goal was to take a messy, unformatted dataset and transform it into a highly reliable, structured, and analysis-ready table without altering the original raw data.

## 🛠️ Tech Stack
*   **Database:** DuckDB
*   **Language:** SQL

## 🧠 Methodology & Thought Process (Key Highlights)
Instead of performing destructive `UPDATE` or `DELETE` operations on the raw table, I built an **idempotent (repeatable) data pipeline** using a single `CREATE OR REPLACE TABLE` statement. 

*   **Data Immutability:** The `raw_data` table remains untouched for auditing purposes. All cleaning is done in the `cleaned_housing_data` layer.
*   **Efficiency:** Used Window Functions (`COALESCE` and `FIRST_VALUE`) to populate missing property addresses by referencing matching `ParcelID`s, avoiding complex self-joins.
*   **Duplicate Removal:** Utilized the `QUALIFY ROW_NUMBER()` clause to ensure only unique records are ingested into the final table.
*   **Standardization:** Split combined addresses into individual columns, standardized date formats to `DD-MMM-YYYY`, and fixed inconsistencies in categorical variables (e.g., `Y/N` to `Yes/No`).

*For a detailed step-by-step breakdown of my exploration and testing process, please refer to the `Data_Cleaning_Workbook.pdf` included in this repository.*

## 📂 Repository Structure
*   `Nashville-Housing-Data.xlsx`: The original raw dataset.
*   `data_cleaning_pipeline.sql`: The final, production-ready SQL script containing all transformations.
*   `Data_Cleaning_Workbook.pdf`: A comprehensive document showcasing the EDA, thought process, and step-by-step code execution.

## 🚀 How to Run the Code
1. Clone this repository.
2. Open your DuckDB interface (CLI or UI).
3. Update the file path in the `read_xlsx()` function inside the `.sql` file to match your local directory.
4. Execute the `.sql` script. It will load the raw data and automatically generate the final `cleaned_housing_data` table.
