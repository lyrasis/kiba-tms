# frozen_string_literal: true

module Kiba
  module Tms
    module ValuationControl
      extend Dry::Configurable
      extend Tms::Mixins::CsTargetable

      module_function

      # @return [nil, Proc] Kiba.job_segment definition of transforms to be run
      #   at the beginning of :valuation_control__from_obj_insurance
      setting :obj_insurance_pre_xforms, default: nil, reader: true
    end
  end
end
