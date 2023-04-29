# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module AccessionLot
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[sortnumber lotcount],
        reader: true,
        constructor: proc { |value| set_deletes(value) }
      setting :non_content_fields,
        default: %i[acquisitionlotid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :has_valuations,
        default: false,
        reader: true,
        constructor: proc { |value|
          empty_fields.any?(:accessionvalue) ? false : true
        }

      setting :con_ref_name_merge_rules,
        default: Tms::ObjAccession.con_ref_name_merge_rules,
        reader: true

      def set_deletes(value)
        if Tms::ObjAccession.accessionvalue_treatment == :valuation_control
          value << :accessionvalue
          value
        end
      end
      private :set_deletes
    end
  end
end
