# frozen_string_literal: true

module Kiba
  module Tms
    module Works
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::CsTargetable
    end
  end
end
