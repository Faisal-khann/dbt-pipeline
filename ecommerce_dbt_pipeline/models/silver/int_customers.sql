{{ config(
    materialized='table',
    schema='SILVER'
) }}

with raw_customers as (
    select * from {{ ref('stg_customers') }}
),

deduped as (
    select
        *,
        row_number() over (
            partition by customer_id 
            order by _ingested_at desc
        ) as rn
    from raw_customers
)

select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_sk,
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    initcap(trim(customer_city)) as customer_city,
    upper(trim(customer_state)) as customer_state,
    {{ add_audit_columns() }}
from deduped
where rn = 1