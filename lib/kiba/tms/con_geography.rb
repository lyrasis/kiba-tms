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

      setting :cleaner,
        default: nil,
        reader: true
    end
  end
end
