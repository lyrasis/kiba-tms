# frozen_string_literal: true

module Kiba
  module Tms
    module ConGeography
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[keyfieldssearchvalue primarydisplay],
        reader: true
      # @return [Array<Symbol>] ID and other always-unique fields not treated as
      #   content for reporting, etc.
      setting :non_content_fields,
        default: %i[congeographyid constituentid geocodeid geocode],
        reader: true
      extend Tms::Mixins::Tableable

      # Optional transform class to clean up table data
      #   and prepare it for merging into person and org records
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
      #
      # Behavior of default merger:
      # - First birth place value is mapped to birthplace (person) or
      #   foundingplace (org)
      # - "Additional birth/founding place: " prepended to each subsequent birth
      #   place value. (Exact label different for person vs. org). These notes
      #   get combined with other field values into bionote (person) or
      #   historynote (org)
      # - First death place value is mapped to deathplace (person) or
      #   dissolutionplace (org)
      # - "Additional death/dissolution place: " prepended to each subsequent
      #   death place value. (Exact label different for person vs. org). These
      #   notes get combined with other field values into bionote (person) or
      #   historynote (org)
      # - All ConGeography values without a birth/death type assigned are
      #   combined (no prefix added) with other field values into bionote
      #   (person) or historynote (org)
      setting :merger,
        default: Tms::Transforms::ConGeography::Merger,
        reader: true
    end
  end
end
