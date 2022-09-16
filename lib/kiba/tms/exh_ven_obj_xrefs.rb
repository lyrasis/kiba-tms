# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ExhVenObjXrefs
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      module_function

      setting :delete_fields,
        default: %i[lightexpluxperhour remarks begindispldateiso enddispldateiso catalognumber],
        reader: true
      setting :empty_fields, default: {}, reader: true
    end
  end
end
