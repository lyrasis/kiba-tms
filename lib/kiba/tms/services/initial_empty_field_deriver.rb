# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Services
      class InitialEmptyFieldDeriver
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        def self.call(...)
          self.new(...).call
        end
        
        def initialize(mod)
          @mod = mod
          @setting_name = "#{mod}.config.empty_fields"
        end

        def call
          return Failure("#{mod} -- no :empty_fields setting") unless mod.respond_to?(:empty_fields)
          _table = yield(ensure_table)
          _checkable_set = yield(set_checkable_fields)
          checked = yield(check)
          
          return nil if checked.empty.empty?

          Success("#{setting_name} = #{checked.empty.to_h.inspect}")
        end

        private

        attr_reader :mod, :setting_name

        def check
          result = Tms::Services::EmptyFieldsChecker.call(mod.table, mod)
        rescue StandardError => err
          Failure([setting_name, err])
        else
          Success(result)
        end
        
        def empty_field_hash(arr)
          arr.map{ |emptyfield| [emptyfield, [nil, '', '0', '.0000']] }.to_h
        end

        def ensure_table
          unless File.exist?(mod.table_path)
            Kiba::Extend::Command::Run.job(table.filekey)
          end
        rescue StandardError => err
          Failure([setting_name, err])
        else
          Success()
        end
        
        def set_checkable_fields
          all = mod.all_fields - Tms.tms_fields
          not_deleted = mod.respond_to?(:delete_fields) ? all - mod.delete_fields : all
          final = not_deleted - mod.empty_fields.keys
          merged = mod.empty_fields.merge(empty_field_hash(final))
          mod.config.send(:empty_fields=, merged)
        rescue StandardError => err
          Failure([setting_name, err])
        else
          Success()
        end
      end
    end
  end
end
