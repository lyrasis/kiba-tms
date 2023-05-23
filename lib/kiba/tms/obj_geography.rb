# frozen_string_literal: true

module Kiba
  module Tms
    module ObjGeography
      extend Dry::Configurable
      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[keyfieldssearchvalue],
        reader: true

      # @return [Array<Symbol>] ID and other always-unique fields not treated as
      #   content for reporting, etc.
      def non_content_fields
        %i[objgeographyid objectid geocode primarydisplay]
      end
      extend Tms::Mixins::Tableable

      # TMS GeoCode values that will be mapped to place authority-controlled
      #   fields in CS
      setting :controlled_types,
        default: [],
        reader: true

      # Whether to remove parts of terms indicating proximity (near, or close
      #   to) from the values that will become authority terms, moving these
      #   strings to a separate :proximity field, which can be merged in as
      #   role or note field value associated with a particular use of the
      #   term in an object record.
      #
      # You may want this set to `false` if:
      #
      # - You want to have separate authority terms for "Paris" and
      #   "near Paris"; or
      # - Your type_to_object_field_mapping includes CS object fields
      #   without associated role, type, or note field per place value
      setting :proximity_as_note,
        default: true,
        reader: true

      # Custom transform classes to clean data in the table at the end of the
      #   initial prep process. Transforms will be carried out in order listed.
      setting :prep_cleaners,
        default: [
          # When a whole field value is wrapped in parentheses, the outer
          #   parentheses are removed. "(This)" becomes "This", while
          #   "New York (NY)" would be left the same.
          Tms::Transforms::ObjGeography::RemoveFullParentheticals
        ],
        reader: true
    end
  end
end
