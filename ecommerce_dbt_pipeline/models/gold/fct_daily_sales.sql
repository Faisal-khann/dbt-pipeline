{{ config(
    materialized='table',
    schema='GOLD'
) }}

with orders as (
    select * from {{ ref('int_orders') }}
),

payments as (
    select * from {{ ref('int_payments') }}
),

order_payments_agg as (
    select
        order_id,
        sum(payment_value) as total_order_value,
        max(payment_installments) as max_installments,
        count(distinct payment_type) as payment_methods_used
    from payments
    group by 1
),

daily_metrics as (
    select
        date_trunc('day', o.order_purchase_timestamp) as sales_date,
        count(distinct o.order_id) as total_orders,
        count(distinct case when o.order_status = 'DELIVERED' then o.order_id end) as delivered_orders,
        count(distinct case when o.order_status = 'CANCELED' then o.order_id end) as canceled_orders,
        count(distinct o.customer_id) as active_customers,
        sum(p.total_order_value) as gross_revenue,
        avg(p.total_order_value) as average_order_value,
        avg(o.delivery_lead_time_days) as avg_delivery_time_days
    from orders o
    left join order_payments_agg p on o.order_id = p.order_id
    group by 1
)

select
    sales_date,
    total_orders,
    delivered_orders,
    canceled_orders,
    active_customers,
    coalesce(gross_revenue, 0.00) as gross_revenue,
    round(coalesce(average_order_value, 0.00), 2) as average_order_value,
    round(coalesce(avg_delivery_time_days, 0.0), 1) as avg_delivery_time_days,
    round((delivered_orders::float / nullif(total_orders, 0)) * 100, 2) as fulfillment_rate_pct,
    current_timestamp() as _mart_updated_at
from daily_metrics