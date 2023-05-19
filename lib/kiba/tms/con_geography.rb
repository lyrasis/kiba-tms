# frozen_string_literal: true

module Kiba
  module Tms
    module ConGeography
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[keyfieldssearchvalue primarydisplay],
        reader: true
      setting :non_content_fields,
        default: %i[congeographyid constituentid geocodeid geocode],
        reader: true
      extend Tms::Mixins::Tableable

      # Project-specific transforms to prepare ConGeography data for merge
      #   into person and org records.
      #
      # To be compatible with the default mergers, the cleaner should add the
      #   following fields to each row:
      #
      # - :type - allowed values: birth, death, blank
      # - :mergeable - the value (with any necessary prefix) to merge
      setting :cleaner,
        default: nil,
        reader: true

      # Transform class that merges ConGeography table values into person
      #   and organization records derived from Constituents table. If
      #   needed, a project-specific transform can be defined
      setting :merger,
        default: Tms::Transforms::ConGeography::Merger,
        reader: true
    end
  end
end
