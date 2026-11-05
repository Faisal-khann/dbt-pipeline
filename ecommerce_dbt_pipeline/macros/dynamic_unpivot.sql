{% macro dynamic_unpivot(relation, pivot_cols, value_col_name, name_col_name) %}
  {% set columns = adapter.get_columns_in_relation(relation) %}
  
  select
    {% for col in columns if col.name not in pivot_cols %}
      {{ col.name }},
    {% endfor %}
    unpivoted_metric.{{ name_col_name }},
    unpivoted_metric.{{ value_col_name }}
  from {{ relation }},
  lateral flatten(input => object_construct(
    {% for col in columns if col.name in pivot_cols %}
      '{{ col.name }}', {{ col.name }}{% if not loop.last %},{% endif %}
    {% endfor %}
  )) as unpivoted_metric({{ name_col_name }}, {{ value_col_name }})
{% endmacro %}