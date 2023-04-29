# frozen_string_literal: true

module Kiba
  module Tms
    module ObjDates
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[],
        reader: true
      setting :empty_fields,
        default: {
          eventtype: [nil, "", "(not entered)", "[not entered]"]
        },
        reader: true
      setting :non_content_fields,
        default: %i[objdateid objectid],
        reader: true
      extend Tms::Mixins::Tableable

      # Whether to remove rows marked inactive from migration. If true, only
      #   rows with :active == 1 will be kept.
      setting :drop_inactive, default: false, reader: true

      # # Project-specific transforms to prepare ConGeography data for merge
      # #   into person and org records.
      # #
      # # To be compatible with the default mergers, the cleaner should add the
      # #   following fields to each row:
      # #
      # # - :type - allowed values: birth, death, blank
      # # - :mergeable - the value (with any necessary prefix) to merge
      # setting :cleaner,
      #   default: nil,
      #   reader: true

      # setting :merger,
      #   default: Tms::Transforms::ConGeography::PersonMerger,
      #   reader: true
    end
  end
end
