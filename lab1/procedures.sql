CREATE OR REPLACE PROCEDURE print_schemas_of_table(tablename text)
    LANGUAGE plpgsql AS
$$
DECLARE
    schema_tab CURSOR FOR (
        SELECT tab.relname, space.nspname
        FROM pg_class tab
        JOIN pg_namespace space ON tab.relnamespace = space.oid
        WHERE tab.relname = tablename
        ORDER BY space.nspname
    );
    table_count int;
BEGIN
    SELECT COUNT(DISTINCT nspname)
    INTO table_count
    FROM pg_class tab
    JOIN pg_namespace space ON tab.relnamespace = space.oid
    WHERE relname = tablename;

    IF table_count < 1 THEN
        RAISE EXCEPTION 'Таблица "%" не найдена!', tablename;
    ELSE
        RAISE NOTICE ' ';
        RAISE NOTICE 'Выберите схему, с которой вы хотите получить данные: ';

        FOR col IN schema_tab
            LOOP
                RAISE NOTICE '%', col.nspname;
            END LOOP;

        RAISE NOTICE ' ';
    END IF;
END
$$;


CREATE OR REPLACE PROCEDURE print_table_info(tablename text, schema text)
    LANGUAGE plpgsql AS
$$
DECLARE
    new_tab CURSOR FOR (
        SELECT tab.relname,
               attr.attnum,
               attr.attname,
               typ.typname,
               des.description,
               attr.attnotnull
        FROM pg_class tab
        JOIN pg_namespace space ON tab.relnamespace = space.oid
        JOIN pg_attribute attr ON attr.attrelid = tab.oid
        JOIN pg_type typ ON attr.atttypid = typ.oid
        LEFT JOIN pg_description des ON des.objoid = tab.oid AND des.objsubid = attr.attnum
        WHERE tab.relname = tablename
        AND attr.attnum > 0
        AND space.nspname = schema
        ORDER BY attnum
    );
    table_count int;
    constraint_name text;
    constraint_type char;
BEGIN
    SELECT COUNT(DISTINCT nspname)
    INTO table_count
    FROM pg_class tab
    JOIN pg_namespace space ON tab.relnamespace = space.oid
    WHERE relname = tablename AND space.nspname = schema;

    IF table_count < 1 THEN
        RAISE EXCEPTION 'Таблица "%" не найдена в схеме "%"!', tablename, schema;
    ELSE
        RAISE NOTICE ' ';
        RAISE NOTICE 'Таблица: %', tablename;
        RAISE NOTICE ' ';
        RAISE NOTICE 'No.  Имя столбца      Атрибуты';
        RAISE NOTICE '---  --------------   -------------------------------------------------';

        FOR col IN new_tab
            LOOP
                RAISE NOTICE '% % Type       :  %', RPAD(col.attnum::text, 5, ' '), RPAD(col.attname, 16, ' '),
                    CASE WHEN col.attnotnull THEN CONCAT(col.typname, ' NOT NULL') ELSE col.typname END;

                IF col.description IS NOT NULL THEN
                    RAISE NOTICE '% Comment    :  "%"', RPAD('⠀', 22, ' '), col.description;
                END IF;

                FOR constraint_name, constraint_type IN
                    SELECT conname, contype
                    FROM pg_constraint c
                    JOIN pg_class cl ON c.conrelid = cl.oid
                    JOIN pg_namespace ns ON cl.relnamespace = ns.oid
                    WHERE cl.relname = tablename
                    AND ns.nspname = schema
                    AND col.attnum = any(c.conkey)
                    LOOP
                        CASE constraint_type
                            WHEN 'p' THEN
                                RAISE NOTICE '% Constraint :  %  Primary key', RPAD('⠀', 22, ' '), constraint_name;
                            WHEN 'f' THEN
                                RAISE NOTICE '% Constraint :  %  Foreign key', RPAD('⠀', 22, ' '), constraint_name;
                            WHEN 'u' THEN
                                RAISE NOTICE '% Constraint :  %  Unique', RPAD('⠀', 22, ' '), constraint_name;
                            WHEN 'c' THEN
                                RAISE NOTICE '% Constraint :  %  Check', RPAD('⠀', 22, ' '), constraint_name;
                            WHEN 't' THEN
                                RAISE NOTICE '% Constraint :  %  Trigger', RPAD('⠀', 22, ' '), constraint_name;
                            END CASE;
                    END LOOP;

                RAISE NOTICE ' ';
            END LOOP;
    END IF;
END
$$;