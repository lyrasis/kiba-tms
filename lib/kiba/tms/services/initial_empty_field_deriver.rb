# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class InitialEmptyFieldDeriver
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(mod)
          @mod = mod
        end

        def call
          set_checkable_fields
          result = Tms::Services::EmptyFieldsChecker.call(mod.table, mod)
          return nil if result.empty.empty?

          "#{mod}.config.empty_fields = #{result.empty.to_h.inspect}"
        end

        private

        attr_reader :mod

        def empty_field_hash(arr)
          arr.map{ |e| [e, [nil, '', '0', '.0000']] }.to_h
        end

        def set_checkable_fields
          all = mod.all_fields - Tms.tms_fields
          final = mod.respond_to?(:delete_fields) ? all - mod.delete_fields : all
          mod.config.send(:empty_fields=, empty_field_hash(final))
        end
      end
    end
  end
end
