# frozen_string_literal: true

module Kiba
  module Tms
    module ValuationControl
      extend Dry::Configurable

      module_function

      setting :cs_record_id_field,
        default: :valuationcontrolrefnumber,
        reader: true

      setting :cs_fields,
        default: {
          fcart: %i[valuationcontrolrefnumber valuecurrency valueamount valuedate
            valuerenewaldate valuesourcepersonlocal
            valuesourceorganizationlocal valuetype valuenote]
        },
        reader: true
      extend Tms::Mixins::CsTargetable
    end
  end
end
