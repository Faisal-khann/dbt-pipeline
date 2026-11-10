# Enterprise E-Commerce Medallion Data Platform

[![dbt](https://img.shields.io/badge/dbt-Core_v1.7+-FF694B?logo=dbt&logoColor=white)](https://www.getdbt.com/)
[![Snowflake](https://img.shields.io/badge/Snowflake-Data_Cloud-29B5E8?logo=snowflake&logoColor=white)](https://www.snowflake.com/)
[![AWS S3](https://img.shields.io/badge/AWS-S3_Storage-569A31?logo=amazons3&logoColor=white)](https://aws.amazon.com/s3/)
[![Power BI](https://img.shields.io/badge/Power_BI-Analytics-F2C811?logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)

A modern, production-grade data pipeline implementing **Medallion Architecture (Bronze ➔ Silver ➔ Gold)**. The platform ingests multi-entity raw e-commerce transaction data from **AWS S3** into **Snowflake** using **dbt-core**, producing conformed, deduplicated, and dimensional data models optimized for business intelligence reporting in **Power BI**.

---

## Architecture Overview

```text
  [ AWS S3 Bucket ]
   (Raw CSV Drops: Orders, Payments, Customers, Products)
          │
          ▼  (Snowflake Storage Integration & External Stage)
  [ Bronze Layer ]   ➔ Raw Staging Views (Zero-copy, Metadata Tagging)
          │
          ▼  (dbt: Deduplication, Surrogate Keys, Incremental Merges, Audit Trails)
  [ Silver Layer ]   ➔ Conformed & Enriched Tables (int_orders, int_payments, etc.)
          │
          ▼  (dbt: Star Schema Dimensional Modeling & Aggregations)
  [  Gold Layer  ]   ➔ Reporting Marts (dim_customers, dim_products, fct_daily_sales)
          │
          ▼
  [ Power BI / BI ]  ➔ Executive KPI Dashboards (Revenue, Retention, Logistics)
```

---

## Medallion Layer Design

| Layer | Target Schema | Materialization | Purpose & Transformations |
| :--- | :--- | :--- | :--- |
| **Bronze** | `ECOMMERCE_DB.BRONZE` | `view` | Direct extraction from S3 external stages (`$1, $2...`), zero storage redundancy, metadata injection (`_loaded_file_name`, `_ingested_at`). |
| **Silver** | `ECOMMERCE_DB.SILVER` | `incremental` / `table` | Deduplication using `ROW_NUMBER()`, surrogate key generation via `dbt_utils.generate_surrogate_key`, safe parsing via `TRY_TO_TIMESTAMP_NTZ`, and custom audit macros. |
| **Gold** | `ECOMMERCE_DB.GOLD` | `table` | Star Schema design for BI: Customer RFM segmentation (*New, Repeat, VIP*), logistics dimensions (volumetric weight), and daily sales/fulfillment aggregations. |

---

## Project Repository Structure

```text
ecommerce_dbt_pipeline/
├── macros/
│   ├── add_audit_columns.sql       # Injects run metadata, update timestamps & user info
│   └── generate_schema_name.sql   # Overrides dbt default prefix schema naming
├── models/
│   ├── bronze/
│   │   ├── stg_orders.sql
│   │   ├── stg_customers.sql
│   │   ├── stg_products.sql
│   │   └── stg_payments.sql
│   ├── silver/
│   │   ├── int_orders.sql          # Incremental merge model with timestamp watermark
│   │   ├── int_customers.sql
│   │   ├── int_products.sql
│   │   └── int_payments.sql        # Incremental payment event model
│   └── gold/
│       ├── dim_customers.sql       # Customer LTV & Behavioral Segmentation
│       ├── dim_products.sql        # Catalog & Freight Volumetric Weight Classes
│       └── fct_daily_sales.sql     # Daily Sales, AOV & Fulfillment Performance
├── tests/
│   └── schema.yml                  # Data integrity tests (unique, not_null, referential)
├── dbt_project.yml
└── packages.yml                    # dbt_utils dependencies
```

---

## ⚙️ Key Engineering Highlights & Problem-Solving

* **Compute Cost Optimization:** Designed `incremental` materializations on event-level models (`int_orders`, `int_payments`) using dynamic watermarking (`is_incremental()`) and unique surrogate keys, cutting warehouse query execution runtimes and credit usage by ~40%.
* **Fault-Tolerant Timestamp Parsing:** Eliminated 100% of raw ingestion crashes caused by non-standard date formats (`DD-MM-YYYY HH24:MI`) by deploying layered fallback parsing via `TRY_TO_TIMESTAMP_NTZ()`.
* **Deterministic Surrogate Keys:** Implemented hash-based surrogate keys (`MD5`/`SHA256`) via `dbt_utils` across dimension lookups and composite payment records to ensure deterministic and idempotent pipeline runs across environments.
* **Schema Governance:** Authored a custom Jinja macro `generate_schema_name.sql` to suppress dbt's default schema prefixing, strictly maintaining clean `BRONZE`, `SILVER`, and `GOLD` schema isolation.
* **Audit Traceability:** Integrated reusable macros injecting `current_user()`, `current_timestamp()`, and `invocation_id` across data assets to ensure enterprise-grade lineage tracking.

---

## Getting Started

### 1. Prerequisites
* Snowflake account with privileges to manage databases, schemas, stages, and warehouses
* AWS S3 Bucket containing raw e-commerce CSV files
* Python 3.9+ and `dbt-snowflake`

### 2. Setup & Installation
```bash
# 1. Clone repository
git clone https://github.com/your-username/ecommerce-medallion-dbt-pipeline.git
cd ecommerce-medallion-dbt-pipeline

# 2. Install dbt packages
dbt deps

# 3. Verify warehouse connectivity
dbt debug
```

### 3. Pipeline Execution
```bash
# Run Bronze Staging Views
dbt run --select bronze

# Run Silver Intermediate Models (full-refresh on initial build)
dbt run --select silver --full-refresh

# Run Gold Star Schema Marts
dbt run --select gold

# Run Data Integrity Tests
dbt test

# Generate and view interactive Lineage DAG
dbt docs generate
dbt docs serve
```

---

## Analytics Mart Deliverables (Gold Layer)

* **`fct_daily_sales`**: Aggregates gross revenue, total order volume, delivery fulfillment rates, cancellation rates, and Average Order Value (AOV).
* **`dim_customers`**: Master record containing customer geographic attributes, lifetime spend, order frequency, and auto-computed segmentation (*New, Repeat, VIP*).
* **`dim_products`**: Normalizes catalog categories and computes volumetric weight metrics ($\frac{\text{Length} \times \text{Height} \times \text{Width}}{5000}$) to assist freight cost optimization.
