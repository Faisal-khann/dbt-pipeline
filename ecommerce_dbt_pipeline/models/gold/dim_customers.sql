{{ config(
    materialized='table',
    schema='GOLD'
) }}

with customers as (
    select * from {{ ref('int_customers') }}
),

orders as (
    select * from {{ ref('int_orders') }}
),

payments as (
    select * from {{ ref('int_payments') }}
),

customer_orders as (
    select
        o.customer_id,
        count(distinct o.order_id) as lifetime_orders,
        min(o.order_purchase_timestamp) as first_order_date,
        max(o.order_purchase_timestamp) as most_recent_order_date,
        sum(p.payment_value) as lifetime_spend
    from orders o
    left join payments p on o.order_id = p.order_id
    group by 1
)

select
    c.customer_sk,
    c.customer_id,
    c.customer_unique_id,
    c.customer_zip_code_prefix,
    c.customer_city,
    c.customer_state,
    coalesce(co.lifetime_orders, 0) as lifetime_orders,
    round(coalesce(co.lifetime_spend, 0.00), 2) as lifetime_spend,
    co.first_order_date,
    co.most_recent_order_date,
    case
        when co.lifetime_orders is null or co.lifetime_orders = 0 then 'Inactive'
        when co.lifetime_orders = 1 then 'New Customer'
        when co.lifetime_orders between 2 and 4 then 'Repeat Customer'
        else 'VIP / Frequent Buyer'
    end as customer_segment,
    current_timestamp() as _mart_updated_at
from customers c
left join customer_orders co on c.customer_id = co.customer_id