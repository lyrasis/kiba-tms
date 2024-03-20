# frozen_string_literal: true

module Kiba
  module Tms
    module ExhVenuesXrefs
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[mnemonic venueconxrefid],
        reader: true
      setting :empty_fields,
        default: {
          exhvenuetitleid: [nil, "", "0", "-1"]
        },
        reader: true
      extend Tms::Mixins::Tableable

      # @return [Hash] Key is a boolean field in the table; Value is the prefix
      #   to add to value after it is mapped to yes/no. Boolean fields omitted
      #   from this mapping should be added to :delete_fields
      setting :boolean_fields_mapping,
        default: {
          useindemnity: "Venue will accept indemnity coverage",
          approved: "Venue approved",
          isforeign: "Foreign venue",
          isstoragevenue: "Storage-only venue"
        },
        reader: true

      setting :insurancenote_sources,
        default: %i[insuranceremarks insindnote],
        reader: true

      setting :field_prefixes,
        default: {
          contact: "Venue contact",
          insurancenote: "Venue insurance note(s)",
          titleatvenue: "Venue title",
          remarks: "Venue remarks"
        },
        reader: true

      setting :planningnote_sources,
        default: %i[remarks contact insurancenote],
        reader: true

      setting :curatorialnote_sources,
        default: %i[],
        reader: true

      setting :generalnote_sources,
        default: %i[],
        reader: true

      setting :boilerplatetext_sources,
        default: %i[titleatvenue],
        reader: true

      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            venue: {
              suffixes: %w[person org],
              merge_role: false
            },
            other: {
              suffixes: %w[person org],
              merge_role: true,
              role_suffix: "role"
            }
          }
        },
        reader: true
    end
  end
end
