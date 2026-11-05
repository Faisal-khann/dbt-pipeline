{{ config(
    materialized='incremental',
    unique_key='order_id',
    schema='SILVER',
    on_schema_change='sync_all_columns'
) }}

with raw_orders as (
    select * from {{ ref('stg_orders') }}
    {% if is_incremental() %}
        where order_purchase_timestamp > (select max(order_purchase_timestamp) from {{ this }})
    {% endif %}
),

deduped as (
    select
        *,
        row_number() over (
            partition by order_id 
            order by order_purchase_timestamp desc
        ) as rn
    from raw_orders
)

select
    {{ dbt_utils.generate_surrogate_key(['order_id']) }} as order_sk,
    order_id,
    customer_id,
    upper(trim(order_status)) as order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    datediff('day', order_purchase_timestamp, order_delivered_customer_date) as delivery_lead_time_days,
    {{ add_audit_columns() }}
from deduped
where rn = 1