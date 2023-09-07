# frozen_string_literal: true

module Kiba::Tms::Works
  extend Dry::Configurable

  module_function

  extend Tms::Mixins::CsTargetable
end
