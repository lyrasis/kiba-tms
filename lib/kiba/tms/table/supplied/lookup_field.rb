# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Supplied
        # Return lookup_on value for table's registry hash or nil
        class LookupField
          def self.call(table_key)
            self.new(table_key).call
          end

          def initialize(table_key)
            @table_key = table_key
          end

          def call
            FIELDS[table_key]
          end

          private

          attr_reader :table_key

          FIELDS = {
            constituents: :constituentid,
            departments: :departmentid,
            obj_comp_statuses: :objcompstatusid,
            obj_comp_types: :objcomptypeid,
            objects: :objectid
          }
        end
      end
    end
  end
end
