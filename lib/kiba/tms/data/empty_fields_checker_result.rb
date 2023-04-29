# frozen_string_literal: true

module Kiba
  module Tms
    module Data
      class EmptyFieldsCheckerResult
        attr_reader :status, :mod, :empty, :not_empty

        def initialize(status:, mod:, empty: nil, not_empty: nil)
          @status = status
          @mod = mod
          @empty = empty
          @not_empty = not_empty
        end
      end
    end
  end
end
