{{ config(materialized='view', schema='BRONZE') }}

select
    $1::varchar as product_id,
    $2::varchar as product_category_name,
    $3::number as product_name_length,
    $4::number as product_description_length,
    $5::number as product_photos_qty,
    $6::number as product_weight_g,
    $7::number as product_length_cm,
    $8::number as product_height_cm,
    $9::number as product_width_cm,
    metadata$filename as _loaded_file_name,
    current_timestamp() as _ingested_at
from @ECOMMERCE_DB.BRONZE.s3_raw_stage/products/ 
