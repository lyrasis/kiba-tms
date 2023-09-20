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
        %i[objgeographyid objectid geocodeid geocode primarydisplay]
      end
      extend Tms::Mixins::Tableable

      # Name of field in which value types (some of which may map to controlled
      #   fields, and some of which may not) are indicated. Used by the
      #   `ControllableByType` mixin.
      setting :controlled_type_field,
        default: :geocode,
        reader: true

      # See the following for description of settings and options:
      # https://github.com/lyrasis/kiba-tms/blob/main/lib/kiba/tms/mixins/controllable_by_type.rb
      extend Tms::Mixins::ControllableByType

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
