# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module MediaRenditions
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[parentrendid sortnumber mediasizeid thumbextensionid
                    thumbblobsize loctermid quantitymade quantityavailable],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
