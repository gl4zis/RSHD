\echo 'Введите название таблицы: '
\prompt '' name_of_table
\set tabl_name '\'' :name_of_table '\''

CALL print_schemas_of_table(:tabl_name::text);

\echo 'Введите название схемы: '
\prompt '' name_of_schema
\set name_shema '\'' :name_of_schema '\''

CALL print_table_info(:tabl_name::text, :name_shema::text);