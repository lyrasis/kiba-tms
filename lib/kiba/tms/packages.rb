# frozen_string_literal: true

module Kiba
  module Tms
    module Packages
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[shortcut rbhistoryfolderid templaterecid displayrecid
          bitmapname global locked packagepurposeid],
        reader: true
      extend Tms::Mixins::Tableable

      if used?
        setting :name_fields,
          default: %i[owner],
          reader: true
        extend Tms::Mixins::UncontrolledNameCompileable
      end
      # TMS tables that map to CS authorities, and thus cannot be added to groups
      setting :omit_tables,
        default: %w[Constituents HistEvents ReferenceMaster],
        reader: true
      # List provided worksheets, most recent first. Assumes they are in the
      #   client project directory/to_client subdir
      setting :provided_worksheets,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "to_client", filename)
          end
        }
      # List returned worksheets, most recent first. Assumes they are in the
      #   client project directory/supplied subdir
      setting :returned_files,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "supplied", filename)
          end
        }
      # Indicates whether any cleanup has been returned. If not, we run
      #   everything on base data. If yes, we merge in/overlay cleanup on the
      #   affected base data tables
      setting :selection_done, default: false, reader: true,
        constructor: proc { !returned_files.empty? }

      def provided_worksheet_jobs
        provided_worksheets.map.with_index do |filename, idx|
          "packages__worksheet_provided_#{idx}".to_sym
        end
      end

      def returned_file_jobs
        returned_files.map.with_index do |filename, idx|
          "packages__worksheet_completed_#{idx}".to_sym
        end
      end
    end
  end
end
