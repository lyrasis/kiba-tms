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
            accession_methods: :accessionmethodid,
            alt_nums: :description,
            classifications: :classificationid,
            classification_notations: :classificationnotationid,
            classification_xrefs: :tablerowid,
            constituents: :constituentid,
            con_address: :conaddressid,
            con_alt_names: :altnameid,
            con_dates: :constituentid,
            con_geo_codes: :congeocodeid,
            con_geography: :constituentid,
            con_types: :constituenttypeid,
            con_xrefs: :conxrefid,
            con_xref_details: :recordid,
            countries: :countryid,
            currencies: :currencyid,
            dd_languages: :languageid,
            departments: :departmentid,
            dimension_elements: :elementid,
            dimension_types: :dimensiontypeid,
            dimension_units: :unitid,
            dimensions: :dimitemelemxrefid,
            email_types: :emailtypeid,
            flag_labels: :flagid,
            indemnity_responsibilities: :responsibilityid,
            insurance_responsibilities: :responsibilityid,
            loan_obj_statuses: :loanobjectstatusid,
            loan_obj_xrefs: :loanid,
            loan_purposes: :loanpurposeid,
            loan_statuses: :loanstatusid,
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
            obj_titles: :objectid,
            objects: :objectnumber,
            object_statuses: :objectstatusid,
            overall_conditions: :overallconditionid,
            phone_types: :phonetypeid,
            ref_formats: :formatid,
            relationships: :relationshipid,
            role_types: :roletypeid,
            roles: :roleid,
            shipping_methods: :shippingmethodid,
            status_flags: :recordid,
            survey_types: :surveytypeid,
            term_master_thes: :termmasterid,
            term_master_geo: :termmastergeoid,
            term_types: :termtypeid,
            terms: :termid,
            text_entries: :tablerowid,
            text_types: :texttypeid,
            thes_xref_types: :thesxreftypeid,
            title_types: :titletypeid,
            treatment_priorities: :priorityid
          }
        end
      end
    end
  end
end
