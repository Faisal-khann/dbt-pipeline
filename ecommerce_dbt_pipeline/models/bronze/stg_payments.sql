{{ config(materialized='view', schema='BRONZE') }}

select
    $1::varchar as order_id,
    $2::number as payment_sequential,
    $3::varchar as payment_type,
    $4::number as payment_installments,
    $5::numeric(12, 2) as payment_value,
    metadata$filename as _loaded_file_name,
    current_timestamp() as _ingested_at
from @ECOMMERCE_DB.BRONZE.s3_raw_stage/payments/