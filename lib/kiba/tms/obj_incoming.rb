# frozen_string_literal: true

module Kiba
  module Tms
    module ObjIncoming
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] ID and other always-unique fields not treated as
      #   content for reporting, etc.
      setting :non_content_fields,
        default: %i[objincomingid objectid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :name_fields,
        default: %i[approvedby requestedby courierin courierout cratepaidby
          ininsurpaidby shippingpaidby],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable
    end
  end
end
