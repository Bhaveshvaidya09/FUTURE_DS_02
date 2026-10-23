# Customer Retention & Churn Executive Command Center 📊

![Track Code](https://img.shields.io/badge/Track%20Code-DS%20%28Data%20Science%20%26%20Analytics%29-blue?style=for-the-badge)
![Task](https://img.shields.io/badge/Task-02%20%20Customer%20Retention%20%26%20Churn%20Analysis-teal?style=for-the-badge)
![Repository Name](https://img.shields.io/badge/Repository-FUTURE__DS__02-darkgreen?style=for-the-badge)

---

## 📌 Executive Summary & Financial Exposure
Analyzing **7,043 customer accounts** from the Telco subscriber dataset revealed severe churn bottlenecks:
* **Baseline Churn Rate:** **`26.54%`** (1,869 churned accounts) vs. SaaS target (< 5%).
* **Lost Monthly Recurring Revenue (Lost MRR):** **`$139,130.85 / month`**
* **Annualized Financial Exposure:** **`$1,669,570.20 / year`** ($1.67 Million)
* **Active High-Risk Accounts (ML Score ≥ 70%):** **`835 Accounts`**

---

## 🖼️ Power BI Executive Dashboard Preview

![Executive Dashboard Preview](./dashboard.ss)

---

## 🛠️ Tech Stack & Usage

| Tool / Layer | Specific Implementation & Usage |
| :--- | :--- |
| 🐍 **Python** | Imputed missing `TotalCharges`, engineered `Tenure_Cohort` & `Total_AddOn_Services`. Trained a **Random Forest Classifier (AUC-ROC: 0.813)** and scored active accounts with an individual `Churn_Probability_Pct`. Generated `cohort_retention_heatmap.png`. |
| 🛢️ **SQL Server (SSMS)** | Modeled database `ChurnAnalytics` into a **Star Schema** (1 Fact, 3 Dimensions). Compiled 5 production views (`vw_Customer_360_Master`, `vw_High_Risk_Churn_Watchlist`, etc.) and 10 T-SQL queries using CTEs, `DENSE_RANK()`, and windowed running totals. |
| 📊 **Power BI** | Relational data model with SSMS, 7 centralized **DAX measures** (`Active MRR`, `Lost MRR`, `Overall Churn Rate %`), 4 dynamic slicers, and interactive visual charts. |

---

## 📈 Key Insights & Actionable Playbook

1. **Early Tenure Onboarding (Year 1 Risk):** Month-to-month subscribers in Year 1 churn at **51.4%**.  
   *👉 Action:* Offer a **15% contract upgrade discount** during Month 3 to lock in annual retention.
2. **The "Service Shield" Effect:** Subscribers with 0 add-ons churn at **45.8%**, while those with 3+ add-ons churn at **< 10%**.  
   *👉 Action:* Bundle free 6-month Tech Support and Online Security into entry-level Fiber Optic tiers.
3. **Payment Method Friction:** Electronic Check users account for **$84,289 in lost MRR** (60.6% of monthly revenue leakage).  
   *👉 Action:* Introduce a **$5/month bill credit** for enrolling in Credit Card or Bank Auto-Pay.
4. **Predictive High-Risk Triage:** The ML model flagged **835 active accounts** at ≥ 70% churn probability.  
   *👉 Action:* Deploy Customer Success teams to issue proactive retention offers before cancellation.

---

## 📁 Repository Structure

FUTURE_DS_02/
│
├── Data/
│   ├── Raw/
│   │   └── WA_Fn-UseC_-Telco-Customer-Churn.xls
│   └── Processed/
│       ├── Dim_Customer.csv
│       ├── Dim_Services.csv
│       ├── Dim_Billing.csv
│       └── Fact_Churn_Retention.csv
│
├── Python Notebook/
│   └── Customer_Churn_and_Retention_EDA.ipynb
│
├── SQL Scripts/
│   └── Customer_Churn_and_Retention_Queries.sql
│
├── Power BI/
│   └── Customer_Churn_Dashboard.pbix
│
├── Documentation/
│   └── Customer_Retention_and_Churn_Master_Report.docx
│
├── dashboard.ss                       # Dashboard Preview Image
├── cohort_retention_heatmap.png       # Generated ML Heatmap Image
└── README.md                          # Repository Documentation


---

## 🚀 Reproduction Quickstart

1. **Python ML & Pipeline:** Run `Python Notebook/Customer_Churn_and_Retention_EDA.ipynb` to clean data, train the Random Forest model, and export processed Star Schema CSVs.
2. **SSMS Data Warehouse:** Import CSVs into database `ChurnAnalytics` and execute `SQL Scripts/Customer_Churn_and_Retention_Queries.sql` to build views and run analytical queries.
3. **Power BI Dashboard:** Open `Power BI/Customer_Churn_Dashboard.pbix`, refresh database connection to `localhost` / `ChurnAnalytics`, and view live visuals.
