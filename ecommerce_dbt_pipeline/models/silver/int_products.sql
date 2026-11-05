{{ config(
    materialized='table',
    schema='SILVER'
) }}

with raw_products as (
    select * from {{ ref('stg_products') }}
)

select
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_sk,
    product_id,
    coalesce(initcap(replace(product_category_name, '_', ' ')), 'Unknown') as product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    {{ add_audit_columns() }}
from raw_products