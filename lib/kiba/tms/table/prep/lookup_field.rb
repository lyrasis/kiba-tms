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
            classifications: :classificationid,
            classification_notations: :classificationnotationid,
            classification_xrefs: :tablerowid,
            constituents: :constituentid,
            con_address: :conaddressid,
            con_alt_names: :altnameid,
            con_types: :constituenttypeid,
            con_xrefs: :conxrefid,
            countries: :countryid,
            departments: :departmentid,
            email_types: :emailtypeid,
            indemnity_responsibilities: :responsibilityid,
            insurance_responsibilities: :responsibilityid,
            locations: :locationid,
            obj_components: :component_id,
            obj_context: :objectid,
            obj_ins_indem_resp: :objinsindemrespid,
            obj_locations: :objlocationid,
            obj_rights_types: :objrightstypeid,
            objects: :objectnumber,
            object_statuses: :objectstatusid,
            phone_types: :phonetypeid,
            role_types: :roletypeid,
            roles: :roleid,
            term_master_thes: :termmasterid,
            term_master_geo: :termmastergeoid,
            term_types: :termtypeid,
            terms: :termid,
            text_entries: :tablerowid,
            text_types: :texttypeid,
            thes_xref_types: :thesxreftypeid
          }
        end
      end
    end
  end
end
