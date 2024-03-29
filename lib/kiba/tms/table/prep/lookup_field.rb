# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Prep
        # Return nil or lookup_on field value for prepped table
        class LookupField
          def self.call(table_key)
            new(table_key).call
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
            accession_lot: :acquisitionlotid,
            accession_methods: :accessionmethodid,
            address_types: Tms::AddressTypes.id_field,
            alt_nums: :lookupkey,
            classifications: :classificationid,
            classification_notations: :classificationnotationid,
            classification_xrefs: :recordid,
            conditions: :conditionid,
            constituents: :constituentid,
            con_address: :conaddressid,
            con_alt_names: :altnameid,
            con_dates: :constituentid,
            con_display_bios: :constituentid,
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
            dimension_methods: :methodid,
            dimension_types: :dimensiontypeid,
            dimension_units: :unitid,
            dimensions: :dimitemelemxrefid,
            disposition_methods: :dispmethodid,
            email_types: :emailtypeid,
            exhibition_obj_statuses: Tms::ExhibitionObjStatuses.id_field,
            exhibition_statuses: Tms::ExhibitionStatuses.id_field,
            exhibitions: :exhibitionid,
            exhibition_titles: :exhibitiontitleid,
            exh_obj_xrefs: :exhobjxrefid,
            exh_venues_xrefs: :exhibitionid,
            flag_labels: :flagid,
            geo_codes: Tms::GeoCodes.id_field,
            indemnity_responsibilities: :responsibilityid,
            insurance_responsibilities: :responsibilityid,
            loan_obj_statuses: :loanobjectstatusid,
            loan_obj_xrefs: :loanid,
            loan_purposes: :loanpurposeid,
            loan_statuses: :loanstatusid,
            loans: :loanid,
            loc_approvers: :approverid,
            loc_handlers: :handlerid,
            loc_purposes: :locpurposeid,
            locations: :locationid,
            media_master: :primaryrendid,
            media_paths: Tms::MediaPaths.id_field,
            media_renditions: :renditionid,
            media_statuses: Tms::MediaStatuses.id_field,
            media_types: Tms::MediaTypes.id_field,
            obj_comp_statuses: :objcompstatusid,
            obj_comp_types: :objcomptypeid,
            obj_components: :component_id,
            obj_context: :objectid,
            obj_dates: :objectid,
            obj_deaccession: :deaccessionid,
            obj_geography: :objectid,
            obj_inc_purposes: :inpurposeid,
            obj_ins_indem_resp: :objinsindemrespid,
            obj_locations: :objlocationid,
            obj_rights_types: :objrightstypeid,
            obj_rights: :objrightsid,
            obj_titles: :objectid,
            object_levels: Tms::ObjectLevels.id_field,
            object_name_types: Tms::ObjectNameTypes.id_field,
            object_names: :objectid,
            objects: :objectnumber,
            object_statuses: Tms::ObjectStatuses.id_field,
            object_types: Tms::ObjectTypes.id_field,
            overall_conditions: :overallconditionid,
            package_folders: :folderid,
            phone_types: :phonetypeid,
            ref_formats: Tms::RefFormats.id_field,
            reference_master: :referenceid,
            registration_sets: :registrationsetid,
            relationships: :relationshipid,
            role_types: :roletypeid,
            roles: :roleid,
            shipping_methods: :shippingmethodid,
            status_flags: :recordid,
            survey_attr_types: :attributetypeid,
            survey_types: :surveytypeid,
            term_master_thes: :termmasterid,
            term_master_geo: :termmastergeoid,
            term_types: :termtypeid,
            terms: :termid,
            text_entries: :recordid,
            text_statuses: Tms::TextStatuses.id_field,
            text_types: :texttypeid,
            thes_xref_types: :thesxreftypeid,
            title_types: :titletypeid,
            trans_codes: :transcodeid,
            trans_status: :transstatusid,
            treatment_priorities: :priorityid,
            user_fields: :userfieldid,
            valuation_purposes: Tms::ValuationPurposes.id_field
          }
        end
      end
    end
  end
end
