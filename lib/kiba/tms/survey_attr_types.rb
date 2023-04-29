# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module SurveyAttrTypes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :attributetypeid, reader: true
      setting :type_field, default: :attributetype, reader: true
      setting :used_in,
        default: [
          "CondLineItems.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
