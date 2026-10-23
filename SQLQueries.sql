-- =================================================================================
-- PART 3 (FAIL-SAFE): 10 ADVANCED BUSINESS PROBLEM-SOLVING QUERIES
-- Description: T-SQL analytical queries utilizing CTEs, Window Functions, 
--              and safe data type handling for SSMS.
-- Database: ChurnAnalytics
-- =================================================================================

USE ChurnAnalytics;
GO

-- ---------------------------------------------------------------------------------
-- QUERY 1: Overall Churn & Revenue Exposure Baseline
-- Problem: What is the executive baseline for total churn, active MRR, lost MRR, 
--          and annualized revenue loss?
-- ---------------------------------------------------------------------------------
SELECT 
    COUNT(customerID) AS Total_Customers,
    SUM(CAST(Churn_Value AS INT)) AS Total_Churned_Customers,
    CAST(ROUND((SUM(CAST(Churn_Value AS INT)) * 100.0) / COUNT(customerID), 2) AS DECIMAL(5,2)) AS Overall_Churn_Rate_Pct,
    CAST(ROUND(SUM(CASE WHEN CAST(Churn_Value AS INT) = 0 THEN MonthlyCharges ELSE 0 END), 2) AS DECIMAL(12,2)) AS Active_MRR,
    CAST(ROUND(SUM(CASE WHEN CAST(Churn_Value AS INT) = 1 THEN MonthlyCharges ELSE 0 END), 2) AS DECIMAL(12,2)) AS Lost_MRR,
    CAST(ROUND(SUM(CASE WHEN CAST(Churn_Value AS INT) = 1 THEN MonthlyCharges ELSE 0 END) * 12.0, 2) AS DECIMAL(12,2)) AS Annualized_Revenue_Loss_ARR
FROM Fact_Churn_Retention;

-- ---------------------------------------------------------------------------------
-- QUERY 2: Tenure Cohort Churn Velocity & Revenue Loss Matrix
-- Problem: At which tenure stage do customers churn fastest, and how much MRR is lost?
-- ---------------------------------------------------------------------------------
SELECT 
    Tenure_Cohort,
    COUNT(customerID) AS Total_Cohort_Customers,
    SUM(CAST(Churn_Value AS INT)) AS Churned_Customers,
    CAST(ROUND((SUM(CAST(Churn_Value AS INT)) * 100.0) / COUNT(customerID), 2) AS DECIMAL(5,2)) AS Churn_Rate_Pct,
    CAST(ROUND(SUM(MonthlyCharges), 2) AS DECIMAL(12,2)) AS Cohort_Total_MRR,
    CAST(ROUND(SUM(CASE WHEN CAST(Churn_Value AS INT) = 1 THEN MonthlyCharges ELSE 0 END), 2) AS DECIMAL(12,2)) AS Cohort_Lost_MRR,
    CAST(ROUND(AVG(tenure), 1) AS DECIMAL(4,1)) AS Avg_Tenure_Months
FROM Fact_Churn_Retention
GROUP BY Tenure_Cohort
ORDER BY Churn_Rate_Pct DESC;

-- ---------------------------------------------------------------------------------
-- QUERY 3: Contract Type & Payment Method Friction Analysis
-- Problem: Which combinations of Contract Type and Payment Method cause the highest churn?
-- ---------------------------------------------------------------------------------
WITH PaymentContractCTE AS (
    SELECT 
        b.Contract,
        b.PaymentMethod,
        COUNT(f.customerID) AS Customer_Count,
        SUM(CAST(f.Churn_Value AS INT)) AS Churned_Count,
        SUM(f.MonthlyCharges) AS Total_MRR,
        SUM(CASE WHEN CAST(f.Churn_Value AS INT) = 1 THEN f.MonthlyCharges ELSE 0 END) AS Lost_MRR
    FROM Dim_Billing b
    INNER JOIN Fact_Churn_Retention f ON b.customerID = f.customerID
    GROUP BY b.Contract, b.PaymentMethod
)
SELECT 
    Contract,
    PaymentMethod,
    Customer_Count,
    Churned_Count,
    CAST(ROUND((Churned_Count * 100.0) / Customer_Count, 2) AS DECIMAL(5,2)) AS Churn_Rate_Pct,
    CAST(ROUND(Lost_MRR, 2) AS DECIMAL(12,2)) AS Lost_MRR,
    DENSE_RANK() OVER (ORDER BY (Churned_Count * 100.0) / Customer_Count DESC) AS Risk_Rank
FROM PaymentContractCTE
ORDER BY Risk_Rank ASC;

-- ---------------------------------------------------------------------------------
-- QUERY 4: The "TechSupport & Security" Protection Shield
-- Problem: How significantly does having Tech Support and Online Security lower churn?
-- ---------------------------------------------------------------------------------
SELECT 
    s.TechSupport,
    s.OnlineSecurity,
    COUNT(f.customerID) AS Total_Customers,
    SUM(CAST(f.Churn_Value AS INT)) AS Churned_Customers,
    CAST(ROUND((SUM(CAST(f.Churn_Value AS INT)) * 100.0) / COUNT(f.customerID), 2) AS DECIMAL(5,2)) AS Churn_Rate_Pct,
    CAST(ROUND(AVG(f.MonthlyCharges), 2) AS DECIMAL(10,2)) AS Avg_Monthly_Charge
FROM Dim_Services s
INNER JOIN Fact_Churn_Retention f ON s.customerID = f.customerID
GROUP BY s.TechSupport, s.OnlineSecurity
ORDER BY Churn_Rate_Pct DESC;

-- ---------------------------------------------------------------------------------
-- QUERY 5: Add-On Service Saturation vs Churn Rate
-- Problem: Does increasing add-on service adoption (0 to 6) reduce churn systematically?
-- ---------------------------------------------------------------------------------
SELECT 
    s.Total_AddOn_Services,
    COUNT(f.customerID) AS Customer_Count,
    SUM(CAST(f.Churn_Value AS INT)) AS Churned_Count,
    CAST(ROUND((SUM(CAST(f.Churn_Value AS INT)) * 100.0) / COUNT(f.customerID), 2) AS DECIMAL(5,2)) AS Churn_Rate_Pct,
    CAST(ROUND(AVG(f.Churn_Probability_Pct), 2) AS DECIMAL(5,2)) AS Avg_Predicted_Churn_Prob_Pct,
    CAST(ROUND(AVG(f.MonthlyCharges), 2) AS DECIMAL(10,2)) AS Avg_Monthly_Charges
FROM Dim_Services s
INNER JOIN Fact_Churn_Retention f ON s.customerID = f.customerID
GROUP BY s.Total_AddOn_Services
ORDER BY s.Total_AddOn_Services ASC;

-- ---------------------------------------------------------------------------------
-- QUERY 6: High-Value Active Customer Triage (CLV at Risk)
-- Problem: Who are the top 20 highest-paying active customers most likely to churn?
-- ---------------------------------------------------------------------------------
SELECT TOP 20
    f.customerID,
    b.Contract,
    b.PaymentMethod,
    f.MonthlyCharges,
    f.TotalCharges,
    f.tenure,
    f.Churn_Probability_Pct,
    s.InternetService,
    s.TechSupport
FROM Fact_Churn_Retention f
INNER JOIN Dim_Billing b  ON f.customerID = b.customerID
INNER JOIN Dim_Services s ON f.customerID = s.customerID
WHERE CAST(f.Churn_Value AS INT) = 0
ORDER BY f.Churn_Probability_Pct DESC, f.MonthlyCharges DESC;

-- ---------------------------------------------------------------------------------
-- QUERY 7: Internet Service Type Price Sensitivity & Churn Comparison
-- Problem: Are Fiber Optic users churning due to high prices compared to DSL users?
-- ---------------------------------------------------------------------------------
SELECT 
    s.InternetService,
    b.Value_Segment,
    COUNT(f.customerID) AS Customer_Count,
    SUM(CAST(f.Churn_Value AS INT)) AS Churned_Count,
    CAST(ROUND((SUM(CAST(f.Churn_Value AS INT)) * 100.0) / COUNT(f.customerID), 2) AS DECIMAL(5,2)) AS Churn_Rate_Pct,
    CAST(ROUND(AVG(f.MonthlyCharges), 2) AS DECIMAL(10,2)) AS Avg_Monthly_Charges
FROM Dim_Services s
INNER JOIN Dim_Billing b ON s.customerID = b.customerID
INNER JOIN Fact_Churn_Retention f ON s.customerID = f.customerID
GROUP BY s.InternetService, b.Value_Segment
ORDER BY s.InternetService, Churn_Rate_Pct DESC;

-- ---------------------------------------------------------------------------------
-- QUERY 8: Demographic Vulnerability Index (Seniors & Household Structure)
-- Problem: How do Senior Status, Partner, and Dependents interact to influence churn?
-- ---------------------------------------------------------------------------------
SELECT 
    CASE WHEN c.SeniorCitizen = 1 THEN 'Senior' ELSE 'Non-Senior' END AS Senior_Status,
    c.Partner,
    c.Dependents,
    COUNT(f.customerID) AS Total_Customers,
    SUM(CAST(f.Churn_Value AS INT)) AS Churned_Customers,
    CAST(ROUND((SUM(CAST(f.Churn_Value AS INT)) * 100.0) / COUNT(f.customerID), 2) AS DECIMAL(5,2)) AS Churn_Rate_Pct,
    CAST(ROUND(AVG(f.tenure), 1) AS DECIMAL(4,1)) AS Avg_Tenure_Months
FROM Dim_Customer c
INNER JOIN Fact_Churn_Retention f ON c.customerID = f.customerID
GROUP BY c.SeniorCitizen, c.Partner, c.Dependents
ORDER BY Churn_Rate_Pct DESC;

-- ---------------------------------------------------------------------------------
-- QUERY 9: Payment Automation Friction: Automatic vs Manual Payments
-- Problem: How does automatic payment setup (Credit Card / Bank Transfer) impact retention?
-- ---------------------------------------------------------------------------------
WITH PaymentCategoryCTE AS (
    SELECT 
        b.PaymentMethod,
        CASE 
            WHEN b.PaymentMethod LIKE '%automatic%' THEN 'Automatic Payment'
            ELSE 'Manual Payment'
        END AS Payment_Category,
        f.customerID,
        CAST(f.Churn_Value AS INT) AS Churn_Value,
        f.MonthlyCharges
    FROM Dim_Billing b
    INNER JOIN Fact_Churn_Retention f ON b.customerID = f.customerID
)
SELECT 
    Payment_Category,
    COUNT(customerID) AS Customer_Count,
    SUM(Churn_Value) AS Churned_Count,
    CAST(ROUND((SUM(Churn_Value) * 100.0) / COUNT(customerID), 2) AS DECIMAL(5,2)) AS Churn_Rate_Pct,
    CAST(ROUND(SUM(CASE WHEN Churn_Value = 1 THEN MonthlyCharges ELSE 0 END), 2) AS DECIMAL(12,2)) AS Monthly_Revenue_Lost
FROM PaymentCategoryCTE
GROUP BY Payment_Category;

-- ---------------------------------------------------------------------------------
-- QUERY 10: Cumulative Revenue Loss & Pareto Risk Distribution (Window Functions)
-- Problem: What is the cumulative percentage of lost monthly revenue across Contract types?
-- ---------------------------------------------------------------------------------
WITH ContractLossCTE AS (
    SELECT 
        b.Contract,
        SUM(f.MonthlyCharges) AS Total_MRR,
        SUM(CASE WHEN CAST(f.Churn_Value AS INT) = 1 THEN f.MonthlyCharges ELSE 0 END) AS Lost_MRR
    FROM Dim_Billing b
    INNER JOIN Fact_Churn_Retention f ON b.customerID = f.customerID
    GROUP BY b.Contract
)
SELECT 
    Contract,
    CAST(ROUND(Total_MRR, 2) AS DECIMAL(12,2)) AS Total_MRR,
    CAST(ROUND(Lost_MRR, 2) AS DECIMAL(12,2)) AS Lost_MRR,
    CAST(ROUND((Lost_MRR * 100.0) / SUM(Lost_MRR) OVER(), 2) AS DECIMAL(5,2)) AS Pct_Of_Total_Revenue_Lost,
    CAST(ROUND(SUM(Lost_MRR) OVER(ORDER BY Lost_MRR DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS DECIMAL(12,2)) AS Cumulative_Lost_MRR
FROM ContractLossCTE
ORDER BY Lost_MRR DESC;