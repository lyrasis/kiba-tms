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
            alt_nums: :description,
            classifications: :classificationid,
            classification_notations: :classificationnotationid,
            classification_xrefs: :tablerowid,
            constituents: :constituentid,
            con_address: :conaddressid,
            con_alt_names: :altnameid,
            con_types: :constituenttypeid,
            con_xrefs: :conxrefid,
            con_xref_details: :recordid,
            countries: :countryid,
            departments: :departmentid,
            dimension_elements: :elementid,
            dimension_types: :dimensiontypeid,
            dimension_units: :unitid,
            dimensions: :dimitemelemxrefid,
            email_types: :emailtypeid,
            flag_labels: :flagid,
            indemnity_responsibilities: :responsibilityid,
            insurance_responsibilities: :responsibilityid,
            loan_purposes: :loanpurposeid,
            loc_approvers: :approverid,
            loc_handlers: :handlerid,
            locations: :locationid,
            obj_comp_statuses: :objcompstatusid,
            obj_comp_types: :objcomptypeid,
            obj_components: :component_id,
            obj_context: :objectid,
            obj_inc_purposes: :inpurposeid,
            obj_ins_indem_resp: :objinsindemrespid,
            obj_locations: :objlocationid,
            obj_rights_types: :objrightstypeid,
            objects: :objectnumber,
            object_statuses: :objectstatusid,
            phone_types: :phonetypeid,
            relationships: :relationshipid,
            role_types: :roletypeid,
            roles: :roleid,
            shipping_methods: :shippingmethodid,
            status_flags: :recordid,
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
