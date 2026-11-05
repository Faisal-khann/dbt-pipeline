{% macro add_audit_columns() %}
    current_user() as _dbt_updated_by,
    current_timestamp() as _dbt_updated_at,
    '{{ invocation_id }}' as _dbt_job_run_id
{% endmacro %}