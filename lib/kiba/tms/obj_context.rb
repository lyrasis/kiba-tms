# frozen_string_literal: true

module Kiba
  module Tms
    module ObjContext
      extend Dry::Configurable

      module_function

      def non_content_fields
        %i[objcontextid objectid]
      end
      extend Tms::Mixins::Tableable

      setting :date_or_chronology_fields,
        default: %i[reign dynasty period],
        reader: true,
        constructor: ->(value) { value - empty_fields.keys }

      # Transforms to clean individual fields. These are run at the
      #   end of the :prep__obj_context job. Elements should be
      #   Kiba-compliant transform classes that do not need to be
      #   initialized with arguments.
      #
      # @return [Array<#process>]
      setting :field_cleaners, default: [], reader: true

      # Used in reportable for_table jobs
      setting :record_num_merge_config,
        default: {
          sourcejob: :prep__obj_context,
          fieldmap: {
            targetrecord: :objectnumber
          }
        }, reader: true
    end
  end
end
