-- =================================================================================
-- PERMANENT SCHEMA & VIEW FIX FOR POWER BI IMPORT
-- Database: ChurnAnalytics
-- =================================================================================

USE ChurnAnalytics;
GO

-- 1. ALTER TABLE SCHEMAS: Convert BIT columns to explicit INT / VARCHAR types
ALTER TABLE Fact_Churn_Retention ALTER COLUMN Churn_Value INT;
ALTER TABLE Fact_Churn_Retention ALTER COLUMN High_Risk_Flag INT;
ALTER TABLE Fact_Churn_Retention ALTER COLUMN Churn VARCHAR(10);

IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('Dim_Customer') AND name = 'SeniorCitizen')
BEGIN
    ALTER TABLE Dim_Customer ALTER COLUMN SeniorCitizen INT;
END
GO

-- 2. REBUILD VIEW 1: vw_Customer_360_Master
CREATE OR ALTER VIEW vw_Customer_360_Master AS
SELECT 
    f.customerID,
    c.gender,
    CAST(c.SeniorCitizen AS INT) AS SeniorCitizen,
    CASE WHEN CAST(c.SeniorCitizen AS INT) = 1 THEN 'Senior' ELSE 'Non-Senior' END AS Senior_Status,
    c.Partner,
    c.Dependents,
    b.Contract,
    b.PaperlessBilling,
    b.PaymentMethod,
    b.Value_Segment,
    s.PhoneService,
    s.MultipleLines,
    s.InternetService,
    s.OnlineSecurity,
    s.OnlineBackup,
    s.DeviceProtection,
    s.TechSupport,
    s.StreamingTV,
    s.StreamingMovies,
    s.Total_AddOn_Services,
    f.tenure,
    f.Tenure_Cohort,
    CAST(ROUND(f.tenure / 12.0, 1) AS DECIMAL(4,1)) AS Tenure_Years,
    f.MonthlyCharges,
    f.TotalCharges,
    CAST(ROUND(f.MonthlyCharges * 12.0, 2) AS DECIMAL(10,2)) AS Estimated_ARR,
    CAST(f.Churn AS VARCHAR(10)) AS Churn,
    CAST(f.Churn_Value AS INT) AS Churn_Value,
    CAST(f.High_Risk_Flag AS INT) AS High_Risk_Flag,
    f.Churn_Probability_Pct,
    CASE 
        WHEN f.Churn_Probability_Pct >= 70.0 THEN 'High Risk'
        WHEN f.Churn_Probability_Pct >= 40.0 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS Churn_Risk_Tier
FROM Fact_Churn_Retention f
INNER JOIN Dim_Customer c ON f.customerID = c.customerID
INNER JOIN Dim_Services s ON f.customerID = s.customerID
INNER JOIN Dim_Billing b  ON f.customerID = b.customerID;
GO

-- 3. REBUILD VIEW 2: vw_Cohort_Retention_Summary
CREATE OR ALTER VIEW vw_Cohort_Retention_Summary AS
SELECT 
    f.Tenure_Cohort,
    b.Contract,
    COUNT(f.customerID) AS Total_Customers,
    SUM(CAST(f.Churn_Value AS INT)) AS Churned_Customers,
    COUNT(f.customerID) - SUM(CAST(f.Churn_Value AS INT)) AS Retained_Customers,
    CAST(ROUND((SUM(CAST(f.Churn_Value AS INT)) * 100.0) / COUNT(f.customerID), 2) AS DECIMAL(5,2)) AS Churn_Rate_Pct,
    CAST(ROUND(((COUNT(f.customerID) - SUM(CAST(f.Churn_Value AS INT))) * 100.0) / COUNT(f.customerID), 2) AS DECIMAL(5,2)) AS Retention_Rate_Pct,
    CAST(ROUND(SUM(f.MonthlyCharges), 2) AS DECIMAL(12,2)) AS Total_Monthly_Revenue,
    CAST(ROUND(SUM(CASE WHEN CAST(f.Churn_Value AS INT) = 1 THEN f.MonthlyCharges ELSE 0 END), 2) AS DECIMAL(12,2)) AS Monthly_Revenue_Lost,
    CAST(ROUND(AVG(f.Churn_Probability_Pct), 2) AS DECIMAL(5,2)) AS Avg_Churn_Probability_Pct
FROM Fact_Churn_Retention f
INNER JOIN Dim_Billing b ON f.customerID = b.customerID
GROUP BY f.Tenure_Cohort, b.Contract;
GO

-- 4. REBUILD VIEW 3: vw_Services_Impact_Analysis
CREATE OR ALTER VIEW vw_Services_Impact_Analysis AS
SELECT 
    s.InternetService,
    s.TechSupport,
    s.OnlineSecurity,
    s.Total_AddOn_Services,
    COUNT(f.customerID) AS Customer_Count,
    SUM(CAST(f.Churn_Value AS INT)) AS Churned_Count,
    CAST(ROUND((SUM(CAST(f.Churn_Value AS INT)) * 100.0) / COUNT(f.customerID), 2) AS DECIMAL(5,2)) AS Churn_Rate_Pct,
    CAST(ROUND(AVG(f.MonthlyCharges), 2) AS DECIMAL(10,2)) AS Avg_Monthly_Charges,
    CAST(ROUND(SUM(CASE WHEN CAST(f.Churn_Value AS INT) = 1 THEN f.MonthlyCharges ELSE 0 END), 2) AS DECIMAL(12,2)) AS Monthly_MRR_At_Risk
FROM Dim_Services s
INNER JOIN Fact_Churn_Retention f ON s.customerID = f.customerID
GROUP BY s.InternetService, s.TechSupport, s.OnlineSecurity, s.Total_AddOn_Services;
GO

-- 5. REBUILD VIEW 4: vw_High_Risk_Churn_Watchlist
CREATE OR ALTER VIEW vw_High_Risk_Churn_Watchlist AS
SELECT 
    f.customerID,
    b.Contract,
    b.PaymentMethod,
    f.tenure,
    f.Tenure_Cohort,
    f.MonthlyCharges,
    f.TotalCharges,
    f.Churn_Probability_Pct,
    s.InternetService,
    s.TechSupport,
    s.OnlineSecurity,
    s.Total_AddOn_Services
FROM Fact_Churn_Retention f
INNER JOIN Dim_Billing b  ON f.customerID = b.customerID
INNER JOIN Dim_Services s ON f.customerID = s.customerID
WHERE CAST(f.Churn_Value AS INT) = 0 
  AND (f.Churn_Probability_Pct >= 60.0 OR CAST(f.High_Risk_Flag AS INT) = 1);
GO

-- 6. REBUILD VIEW 5: vw_Revenue_At_Risk_Executive
CREATE OR ALTER VIEW vw_Revenue_At_Risk_Executive AS
SELECT 
    b.Contract,
    b.Value_Segment,
    b.PaymentMethod,
    COUNT(f.customerID) AS Total_Accounts,
    SUM(CASE WHEN CAST(f.Churn_Value AS INT) = 0 THEN 1 ELSE 0 END) AS Active_Accounts,
    SUM(CASE WHEN CAST(f.Churn_Value AS INT) = 1 THEN 1 ELSE 0 END) AS Churned_Accounts,
    CAST(ROUND(SUM(CASE WHEN CAST(f.Churn_Value AS INT) = 0 THEN f.MonthlyCharges ELSE 0 END), 2) AS DECIMAL(12,2)) AS Active_MRR,
    CAST(ROUND(SUM(CASE WHEN CAST(f.Churn_Value AS INT) = 1 THEN f.MonthlyCharges ELSE 0 END), 2) AS DECIMAL(12,2)) AS Lost_MRR,
    CAST(ROUND(SUM(CASE WHEN CAST(f.Churn_Value AS INT) = 1 THEN f.TotalCharges ELSE 0 END), 2) AS DECIMAL(12,2)) AS Cumulative_Lost_LTV
FROM Dim_Billing b
INNER JOIN Fact_Churn_Retention f ON b.customerID = f.customerID
GROUP BY b.Contract, b.Value_Segment, b.PaymentMethod;
GO