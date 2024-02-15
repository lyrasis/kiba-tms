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

      # ------------------------------------------------------------------------
      # FCART PROFILE NOTE: Birth/founding and death/dissolution place in person
      #   and organization are not controlled values, so this table is not
      #   included in place authority
      # ------------------------------------------------------------------------

      # Name of field in which value types (some of which may map to controlled
      #   fields, and some of which may not) are indicated. Used by the
      #   `ControllableByType` mixin.
      setting :controlled_type_field,
        default: :congeocode,
        reader: true

      # See the following for description of settings and options:
      # https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/mixins/controllable_by_type.rb
      extend Tms::Mixins::ControllableByType

      # Optional transform class to clean up table data mapped to authority
      #   controlled fields, and prepare it for merging into person and org
      #   records
      setting :auth_cleaner,
        default: nil,
        reader: true

      # Transform class that merges ConGeography table values being mapped into
      #   authority controlled fields into person and organization records
      #   derived from Constituents table. If needed, a project-specific
      #   transform can be defined
      setting :auth_merger,
        default: Tms::Transforms::ConGeography::Merger,
        reader: true

      # Optional transform class to clean up table data mapped to non-authority
      #   controlled fields, and prepare it for merging into person and org
      #   records
      #
      # IMPLEMENTATION NOTE: To be compatible with the default merger, the
      #   cleaner should add the following fields to each row:
      #
      # - :type - allowed values: birth, death, blank
      # - :mergeable - the value (with any necessary prefix) to merge
      setting :non_auth_cleaner,
        default: nil,
        reader: true

      # Transform class that merges ConGeography table values being mapped into
      #   non-authority controlled fields into person and organization records
      #   derived from Constituents table. If needed, a project-specific
      #   transform can be defined
      #
      # Behavior of default merger:
      # - First birth place value is mapped to birthplace (person) or
      #   foundingplace (org)
      # - "Additional birth/founding place: " prepended to each subsequent birth
      #   place value. (Exact label different for person vs. org). These notes
      #   get combined with other field values into bionote (person) or
      #   historynote (org)
      # - First death place value is mapped to deathplace (person). There is no
      #   dissolutionplace field in org record
      # - "Additional death/dissolution place: " prepended to each subsequent
      #   death place value. (Exact label different for person vs. org). These
      #   notes get combined with other field values into bionote (person) or
      #   historynote (org)
      # - All ConGeography values without a birth/death type assigned are
      #   combined (no prefix added) with other field values into bionote
      #   (person) or historynote (org)
      setting :non_auth_merger,
        default: Tms::Transforms::ConGeography::Merger,
        reader: true
    end
  end
end
