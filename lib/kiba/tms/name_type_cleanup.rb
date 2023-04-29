# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module NameTypeCleanup
      module_function

      extend Dry::Configurable

      setting :source_job_key,
        default: :name_type_cleanup__from_base_data,
        reader: true

      extend Tms::Mixins::Tableable

      def used?
        true
      end

      # Indicates whether any cleanup has been returned. If not, we run
      #   everything on base data. If yes, we merge in/overlay cleanup on the
      #   affected base data tables
      setting :done, default: false, reader: true,
        constructor: proc{ !returned_files.empty? }
      setting :dropped_name_indicator,
        default: "DROPPED FROM MIGRATION",
        reader: true
      setting :untyped_treatment,
        default: "Person",
        reader: true
      # Client-specific transform to clean returned worksheet before any further
      #   processing is done
      setting :returned_cleaner, default: nil, reader: true
      # List provided worksheets, most recent first. Assumes they are in the
      #   client project directory/to_client subdir
      setting :provided_worksheets,
        default: [],
        reader: true,
        constructor: proc{ |value| value.map do |filename|
              File.join(Kiba::Tms.datadir, "to_client", filename)
            end
        }
      # List returned worksheets, most recent first. Assumes they are in the
      #   client project directory/supplied subdir
      setting :returned_files,
        default: [],
        reader: true,
        constructor: proc{ |value| value.map do |filename|
              File.join(Kiba::Tms.datadir, "supplied", filename)
            end
        }

      setting :targets, default: [], reader: true

      setting :configurable, default: {
        targets: proc{ Tms::Services::NameTypeCleanup::TargetsDeriver.call }
      },
        reader: true

      def initial_headers
        base = %i[
                  name correctname authoritytype correctauthoritytype termsource
                  constituentid
                 ]
        base.unshift(:to_review) if done
        base
      end

      def provided_worksheet_jobs
        provided_worksheets.map.with_index do |filename, idx|
          "name_type_cleanup__worksheet_provided_#{idx}".to_sym
        end
      end

      def returned_file_jobs
        returned_files.map.with_index do |filename, idx|
          "name_type_cleanup__worksheet_completed_#{idx}".to_sym
        end
      end
    end
  end
end
