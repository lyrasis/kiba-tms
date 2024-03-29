# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Supplied
        # Return lookup_on value for table's registry hash or nil
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
            address_types: :addresstypeid,
            con_alt_names: :altnameid,
            cond_line_items: :conditionid,
            conditions: :conditionid,
            constituents: :constituentid,
            dd_contexts: :contextid,
            departments: :departmentid,
            exhibitions: :exhibitionid,
            folder_types: Tms::FolderTypes.id_field,
            loans: :loanid,
            loc_purposes: :locpurposeid,
            locations: :locationid,
            media_files: :fileid,
            obj_comp_statuses: :objcompstatusid,
            obj_comp_types: :objcomptypeid,
            obj_components: :componentid,
            obj_insurance: :objinsuranceid,
            obj_locations: :objlocationid,
            objects: :objectid,
            package_folder_xrefs: :packageid,
            reference_master: :referenceid,
            registration_sets: :lotid,
            thesaurus_bases: :thesaurusbaseid
          }
        end
      end
    end
  end
end
