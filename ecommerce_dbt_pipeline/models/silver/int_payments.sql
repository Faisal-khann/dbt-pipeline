{{ config(
    materialized='incremental',
    unique_key='payment_sk',
    schema='SILVER',
    on_schema_change='sync_all_columns'
) }}

with raw_payments as (
    select * from {{ ref('stg_payments') }}
    
    {% if is_incremental() %}
        -- Load only records ingested after the most recent load
        where _ingested_at > (select coalesce(max(_dbt_updated_at), '1900-01-01'::timestamp_ntz) from {{ this }})
    {% endif %}
),

deduped as (
    select
        *,
        row_number() over (
            partition by order_id, payment_sequential 
            order by _ingested_at desc
        ) as rn
    from raw_payments
)

select
    {{ dbt_utils.generate_surrogate_key(['order_id', 'payment_sequential']) }} as payment_sk,
    order_id,
    payment_sequential,
    lower(trim(payment_type)) as payment_type,
    payment_installments,
    payment_value,
    _ingested_at,
    {{ add_audit_columns() }}
from deduped
where rn = 1
  and order_id is not null






{# {{ config(
    materialized='table',
    schema='SILVER'
) }}

with raw_payments as (
    select * from {{ ref('stg_payments') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['order_id', 'payment_sequential']) }} as payment_sk,
    order_id,
    payment_sequential,
    lower(trim(payment_type)) as payment_type,
    payment_installments,
    payment_value,
    {{ add_audit_columns() }}
from raw_payments #}

