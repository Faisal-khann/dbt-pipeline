{{ config(materialized='view', schema='BRONZE') }}

select
    $1::varchar as order_id,
    $2::varchar as customer_id,
    $3::varchar as order_status,
    -- Handle DD-MM-YYYY HH24:MI or standard YYYY-MM-DD formats safely
    coalesce(
        try_to_timestamp_ntz($4::varchar, 'DD-MM-YYYY HH24:MI'),
        try_to_timestamp_ntz($4::varchar, 'YYYY-MM-DD HH24:MI:SS'),
        try_to_timestamp_ntz($4::varchar)
    ) as order_purchase_timestamp,

    coalesce(
        try_to_timestamp_ntz($5::varchar, 'DD-MM-YYYY HH24:MI'),
        try_to_timestamp_ntz($5::varchar, 'YYYY-MM-DD HH24:MI:SS'),
        try_to_timestamp_ntz($5::varchar)
    ) as order_approved_at,

    coalesce(
        try_to_timestamp_ntz($6::varchar, 'DD-MM-YYYY HH24:MI'),
        try_to_timestamp_ntz($6::varchar, 'YYYY-MM-DD HH24:MI:SS'),
        try_to_timestamp_ntz($6::varchar)
    ) as order_delivered_carrier_date,

    coalesce(
        try_to_timestamp_ntz($7::varchar, 'DD-MM-YYYY HH24:MI'),
        try_to_timestamp_ntz($7::varchar, 'YYYY-MM-DD HH24:MI:SS'),
        try_to_timestamp_ntz($7::varchar)
    ) as order_delivered_customer_date,

    coalesce(
        try_to_timestamp_ntz($8::varchar, 'DD-MM-YYYY HH24:MI'),
        try_to_timestamp_ntz($8::varchar, 'YYYY-MM-DD HH24:MI:SS'),
        try_to_timestamp_ntz($8::varchar)
    ) as order_estimated_delivery_date,

    metadata$filename as _loaded_file_name,
    current_timestamp() as _ingested_at
from @ECOMMERCE_DB.BRONZE.s3_raw_stage/orders/