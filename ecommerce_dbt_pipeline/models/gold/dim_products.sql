{{ config(
    materialized='table',
    schema='GOLD'
) }}

with products as (
    select * from {{ ref('int_products') }}
)

select
    product_sk,
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    -- Logistics KPI: Volumetric weight
    round((product_length_cm * product_height_cm * product_width_cm) / 5000.0, 2) as volumetric_weight_kg,
    case
        when product_weight_g < 500 then 'Lightweight (<0.5kg)'
        when product_weight_g between 500 and 3000 then 'Mediumweight (0.5kg-3kg)'
        when product_weight_g > 3000 then 'Heavyweight (>3kg)'
        else 'Uncategorized'
    end as weight_class,
    current_timestamp() as _mart_updated_at
from products