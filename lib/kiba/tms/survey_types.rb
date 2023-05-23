# frozen_string_literal: true

module Kiba
  module Tms
    module SurveyTypes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :surveytypeid, reader: true
      setting :type_field, default: :surveytype, reader: true
      setting :used_in,
        default: [
          "Conditions.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
