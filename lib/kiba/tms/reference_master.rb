# frozen_string_literal: true

module Kiba
  module Tms
    module ReferenceMaster
      extend Dry::Configurable

      module_function

      setting :citation_note_value_separator, default: Tms.notedelim,
        reader: true

      # @return [Array<Symbol>] fields whose values will be combined into
      #   citationNote field value
      setting :citation_note_sources,
        default: %i[notes boilertext],
        reader: true

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[alphaheading sortnumber publicaccess
          conservationentityid],
        reader: true
      extend Tms::Mixins::Tableable

      # Used in reportable for_table jobs
      setting :record_num_merge_config,
        default: {
          sourcejob: :reference_master__prep,
          fieldmap: {targetrecord: :title}
        }, reader: true

      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            agent: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: true,
              role_suffix: "role"
            },
            publisher: {
              suffixes: %w[organizationlocal],
              merge_role: false
            }
          }
        },
        reader: true

      # List provided placepublished worksheets, most recent first. Assumes they
      #   are in the client project directory/to_client subdir
      setting :placepublished_worksheets,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "to_client", filename)
          end
        }
      # List returned placepublished worksheet files, most recent first. Assumes
      #   they are in the client project directory/supplied subdir
      setting :placepublished_returned,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "supplied", filename)
          end
        }
      # Indicates whether any placepublished cleanup has been returned. If not,
      #   we run everything on base data. If yes, we merge in/overlay cleanup on
      #   the affected base data tables
      setting :placepublished_done, default: false, reader: true,
        constructor: proc { !placepublished_returned.empty? }

      def placepublished_worksheet_jobs
        placepublished_worksheets.map.with_index do |filename, idx|
          "reference_master__pp_worksheet_provided_#{idx}".to_sym
        end
      end

      def placepublished_returned_jobs
        placepublished_returned.map.with_index do |filename, idx|
          "reference_master__pp_worksheet_returned_#{idx}".to_sym
        end
      end
    end
  end
end
