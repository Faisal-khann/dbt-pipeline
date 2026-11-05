{{ config(materialized='view', schema='BRONZE') }}

select
    $1::varchar as customer_id,
    $2::varchar as customer_unique_id,
    $3::varchar as customer_zip_code_prefix,
    $4::varchar as customer_city,
    $5::varchar as customer_state,
    metadata$filename as _loaded_file_name,
    current_timestamp() as _ingested_at
from @ECOMMERCE_DB.BRONZE.s3_raw_stage/customers/

