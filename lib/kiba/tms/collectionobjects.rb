# frozen_string_literal: true

module Kiba
  module Tms
    module Collectionobjects
      extend Dry::Configurable

      setting :cs_record_id_field,
        default: :objectnumber,
        reader: true

      extend Tms::Mixins::CsTargetable

      module_function
    end
  end
end
