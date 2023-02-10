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
            con_alt_names: :altnameid,
            cond_line_items: :conditionid,
            constituents: :constituentid,
            departments: :departmentid,
            exhibitions: :exhibitionid,
            loans: :loanid,
            loc_purposes: :locpurposeid,
            locations: :locationid,
            obj_comp_statuses: :objcompstatusid,
            obj_comp_types: :objcomptypeid,
            obj_components: :componentid,
            obj_insurance: :objinsuranceid,
            objects: :objectid,
            reference_master: :referenceid,
            registration_sets: :lotid,
            thesaurus_bases: :thesaurusbaseid
          }
        end
      end
    end
  end
end
