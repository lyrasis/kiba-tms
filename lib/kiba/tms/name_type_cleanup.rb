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

      # @return [true] if any name_type_cleanup worksheet has been returned. If
      #   true, we merge/overlay cleaned values onto the base data.
      # @return [false] if no name_type_cleanup worksheet has been returned. If
      #   false, we use the base TMS data.
      # Automatically set based on `:returned_files`
      setting :done, default: false, reader: true,
        constructor: proc { !returned_files.empty? }

      # Optional client-specific transform to clean returned worksheet before
      #   any further processing is done
      setting :returned_cleaner, default: nil, reader: true

      # List of provided worksheets, most recent first. Assumes they are in the
      #   client project directory/to_client subdir
      setting :provided_worksheets,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "to_client", filename)
          end
        }

      # List of returned worksheets, most recent first. Assumes they are in the
      #   client project directory/supplied subdir
      setting :returned_files,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "supplied", filename)
          end
        }

      # Auto-generated setting indicating which TMS base data needs to have
      #   name type cleanup merged in
      setting :targets, default: [], reader: true

      setting :configurable,
        default: {
          targets: proc { Tms::Services::NameTypeCleanup::TargetsDeriver.call }
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
