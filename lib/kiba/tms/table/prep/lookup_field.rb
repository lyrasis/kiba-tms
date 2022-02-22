# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Prep
        # Return nil or lookup_on field value for prepped table
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
            con_types: :constituenttypeid,
            con_alt_names: :altnameid,
            departments: :departmentid,
            indemnity_responsibilities: :responsibilityid,
            insurance_responsibilities: :responsibilityid,
            obj_ins_indem_resp: :objinsindemrespid,
            objects: :objectnumber,
            object_statuses: :objectstatusid,
            term_master: :termmasterid,
            term_master_geo: :termmastergeoid,
            term_types: :termtypeid,
            terms: :termid,
            thes_xref_types: :thesxreftypeid
          }
        end
      end
    end
  end
end
