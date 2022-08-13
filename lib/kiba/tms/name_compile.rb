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
                    name_compile__from_con_person_with_inst
                    name_compile__from_con_person_with_position_no_inst
                    name_compile__from_can_typematch_alt_established
                    name_compile__from_can_main_person_alt_org_established
                    name_compile__from_can_main_org_alt_person_established
                    name_compile__from_can_typematch_variant
                    name_compile__from_can_typematch_separate_names
                    name_compile__from_can_typematch_separate_notes
                    name_compile__from_can_typemismatch_main_person
                    name_compile__from_can_typemismatch_main_org
                    name_compile__from_can_no_altnametype
                   ],
        reader: true
      setting :source_treatment,
        default: {
          name_compile__from_con_org_with_inst: :variant,
          # options: :contact_person, :variant
          name_compile__from_con_org_with_name_parts: :contact_person,
          name_compile__from_con_org_with_single_name_part_no_position: :variant,
          # options: :related_contact_person, :variant
          name_compile__from_con_person_with_inst: :related_contact_person,
          # options: :bio_note, :qualifier, :name_note
          name_compile__from_con_person_with_position_no_inst: :bio_note,
          # options: :bio_note, :name_note, :variant
          name_compile__from_can_typematch_alt_established: :bio_note,
          # options: :contact_person, :bio_note, :name_note, :variant
          name_compile__from_can_main_person_alt_org_established: :contact_person,
          # options: :contact_person, :bio_note, :name_note, :variant
          name_compile__from_can_main_org_alt_person_established: :contact_person,
          # This source always creates a new/separate name for the alt name value.
          #   It also adds a "related name" note for the existing constituent and the new
          #   name. This setting controls which note type the related name note maps to
          # options: :bio_note, :name_note
          name_compile__from_can_typematch_separate: :bio_note,
          # options: :contact_person, :variant
          name_compile__from_can_typemismatch_main_person: :contact_person,
          # options: :contact_person, :variant
          name_compile__from_can_typemismatch_main_org: :contact_person
        },
        reader: true
      # When altname is of same type as main name, altnametype values starting with these values
      #   will be treated as variant terms. Other non-blank altnametype values will be treated
      #   as separate names
      setting :altname_typematch_variant_nametypes,
        default: %w[aka alias alternate birth known label maiden primary],
        reader: true
      # How to handle altnames with same type as main name where there is no altnametype and there
      #   is a :position value
      # options: :separate_name, :variant
      setting :altname_typematch_no_nametype_position, default: :separate_name, reader: true
      # How to handle altnames with same type as main name where there is no altnametype and no
      #   :position value
      # options: :separate_name, :variant
      setting :altname_typematch_no_nametype_no_position, default: :variant, reader: true

      # fields that should be nil in person records
      setting :person_nil,
        default: %i[institution position],
        reader: true
      # fields that should be nil in org records
      setting :org_nil,
        default: %i[nametitle firstname middlename lastname suffix institution position salutation],
        reader: true
      setting :derived_nil,
        default: %i[birth_foundation_date death_dissolution_date datenote biography code nationality
                    school remarks culturegroup],
        reader: true
      setting :variant_nil,
        default: [org_nil, person_nil, derived_nil].flatten,
        reader: true
      setting :alt_nil,
        default: %i[conname altname altconname conauthtype altauthtype typematch altnametype altnameconid
                    altconauthtype treatment],
        reader: true

      # Used by Services::NameCompile::RelatedNameNoteText
      # Controls values added at beginning/end of parenthethical relator in notes added to names
      #   derived as main names from entries in altname table
      setting :related_name_note_role_prefix_for_alt, default: '', reader: true
      setting :related_name_note_role_suffix_for_alt, default: ' of', reader: true
      
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

