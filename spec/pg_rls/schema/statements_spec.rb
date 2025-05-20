# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PgRls::Schema::Statements do
  describe 'RLS index methods' do
    let(:dummy_migration) do
      Class.new do
        include PgRls::Schema::Statements

        def self.execute(sql)
          # Store executed SQL for testing
          @executed_sql ||= []
          @executed_sql << sql
        end

        def self.executed_sql
          @executed_sql
        end

        def self.reset_executed_sql
          @executed_sql = []
        end
      end
    end

    before do
      allow(ActiveRecord::Migration).to receive(:execute) do |sql|
        dummy_migration.execute(sql)
      end

      # Reset the executed SQL before each test
      dummy_migration.reset_executed_sql
    end

    describe '#create_rls_index' do
      it 'creates an index with tenant_id as the first column' do
        dummy_migration.new.create_rls_index('users', 'email')
        
        expect(dummy_migration.executed_sql.first).to include('CREATE INDEX')
        expect(dummy_migration.executed_sql.first).to include('index_users_on_tenant_id_and_email')
        expect(dummy_migration.executed_sql.first).to include('(tenant_id, email)')
      end

      it 'handles multiple columns correctly' do
        dummy_migration.new.create_rls_index('users', ['email', 'name'])
        
        expect(dummy_migration.executed_sql.first).to include('(tenant_id, email, name)')
      end

      it 'supports custom index name' do
        dummy_migration.new.create_rls_index('users', 'email', name: 'custom_index_name')
        
        expect(dummy_migration.executed_sql.first).to include('CREATE INDEX custom_index_name')
      end

      it 'supports using clause' do
        dummy_migration.new.create_rls_index('users', 'email', using: 'btree')
        
        expect(dummy_migration.executed_sql.first).to include('USING btree')
      end

      it 'supports where clause' do
        dummy_migration.new.create_rls_index('users', 'email', where: 'email IS NOT NULL')
        
        expect(dummy_migration.executed_sql.first).to include('WHERE email IS NOT NULL')
      end
    end

    describe '#drop_rls_index' do
      it 'drops an index with the generated name' do
        dummy_migration.new.drop_rls_index('users', 'email')
        
        expect(dummy_migration.executed_sql.first).to include('DROP INDEX IF EXISTS')
        expect(dummy_migration.executed_sql.first).to include('index_users_on_tenant_id_and_email')
      end

      it 'supports custom index name' do
        dummy_migration.new.drop_rls_index('users', 'email', name: 'custom_index_name')
        
        expect(dummy_migration.executed_sql.first).to include('DROP INDEX IF EXISTS custom_index_name')
      end
    end
  end
end