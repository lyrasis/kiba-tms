# frozen_string_literal: true

module Kiba
  module Tms
    module ObjDeaccession
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      # @return [nil, Proc] Kiba.job_segment of transforms run at beginning of
      #   :prep__obj_deaccession job.
      setting :pre_prep_xforms, default: nil, reader: true

      # @return [nil, Proc] Kiba.job_segment of transforms run at end of
      #   :prep__obj_deaccession job.
      setting :post_prep_xforms, default: nil, reader: true
    end
  end
end
