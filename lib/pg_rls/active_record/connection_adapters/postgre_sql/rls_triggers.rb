# frozen_string_literal: true

module PgRls
  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        # This module contains the logic to create, drop and validate RLS functions
        module RlsTriggers
          include SqlHelperMethod

          def trigger_exists?(table_name, function_name, schema = PgRls.schema)
            query = <<~SQL
              SELECT 1
              FROM pg_trigger
              WHERE tgname = '#{schema}_#{table_name}_#{function_name}_trigger';
            SQL

            execute_sql!(query).any?
          end

          def append_tenant_table_triggers(table_name, schema = PgRls.schema)
            create_rls_exception_trigger(schema, table_name)
          end

          def append_rls_table_triggers(table_name, schema = PgRls.schema)
            create_tenant_id_setter_trigger(schema, table_name)
            create_tenant_id_update_blocker_trigger(schema, table_name)
          end

          def drop_tenant_table_triggers(table_name, schema = PgRls.schema)
            drop_trigger(schema, table_name, "#{schema}_#{table_name}_rls_exception_trigger")
          end

          def drop_rls_table_triggers(table_name, schema = PgRls.schema)
            drop_trigger(schema, table_name, "#{schema}_#{table_name}_tenant_id_setter_trigger")
            drop_trigger(schema, table_name, "#{schema}_#{table_name}_tenant_id_update_blocker_trigger")
          end

          private

          def drop_trigger(schema, table_name, trigger_name)
            query = <<~SQL
              DROP TRIGGER IF EXISTS #{trigger_name} ON #{schema}.#{table_name};
            SQL

            execute_sql!(query)
          end

          def create_trigger(schema, table_name, trigger_name, function_name, timing, event) # rubocop:disable Metrics/ParameterLists
            query = <<~SQL
              CREATE TRIGGER #{trigger_name}
                #{timing} #{event} ON #{schema}.#{table_name}
                FOR EACH ROW EXECUTE PROCEDURE #{function_name}();
            SQL

            execute_sql!(query)
          end

          def create_rls_exception_trigger(schema, table_name)
            create_trigger(
              schema,
              table_name,
              "#{schema}_#{table_name}_rls_exception_trigger",
              "rls_exception",
              "BEFORE",
              "UPDATE OF tenant_id"
            )
          end

          def create_tenant_id_setter_trigger(schema, table_name)
            create_trigger(
              schema,
              table_name,
              "#{schema}_#{table_name}_tenant_id_setter_trigger",
              "tenant_id_setter",
              "BEFORE",
              "INSERT"
            )
          end

          def create_tenant_id_update_blocker_trigger(schema, table_name)
            create_trigger(
              schema,
              table_name,
              "#{schema}_#{table_name}_tenant_id_update_blocker_trigger",
              "tenant_id_update_blocker",
              "BEFORE",
              "UPDATE OF tenant_id"
            )
          end
        end
      end
    end
  end
end
