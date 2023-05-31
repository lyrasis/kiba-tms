# frozen_string_literal: true

module Kiba
  module Tms
    module ReferenceMaster
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[alphaheading sortnumber publicaccess
          conservationentityid],
        reader: true
      extend Tms::Mixins::Tableable

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
