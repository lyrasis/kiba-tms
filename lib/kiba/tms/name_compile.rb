# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module NameCompile
      module_function
      
      extend Dry::Configurable
      setting :multi_source_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
      setting :sources,
        default: %i[
                    name_compile__from_con_org_plain
                    name_compile__from_con_org_with_inst
                    name_compile__from_con_org_with_name_parts
                    name_compile__from_con_org_with_single_name_part_no_position
                    name_compile__from_con_person_plain
                   ],
        reader: true
      setting :source_treatment,
        default: {
          name_compile__from_con_org_with_inst: :variant,
          name_compile__from_con_org_with_name_parts: :related_contact_person,
          name_compile__from_con_org_with_single_name_part_no_position: :variant
        },
        reader: true
      # fields that should be nil in person records
      setting :person_nil,
        default: %i[institution position],
        reader: true
      # fields that should be nil in org records
      setting :org_nil,
        default: %i[nametitle firstname middlename lastname suffix institution position salutation],
        reader: true
      setting :related_nil,
        default: %i[birth_foundation_date death_dissolution_date datenote biography code nationality
                    school remarks culturegroup],
        reader: true
      setting :variant_nil,
        default: [org_nil, person_nil, related_nil].flatten,
        reader: true
      # Whether to compile :stmtresponsibility field from ReferenceMaster in names list
      # You probably only want to set this to true if ConXrefDetails target tables do not include
      #   ReferenceMaster
      setting :include_ref_stmt_resp, default: false, reader: true
      setting :multi_source_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
      # fields to delete from name compilation report
      setting :delete_fields, default: [], reader: true
    end
  end
end

