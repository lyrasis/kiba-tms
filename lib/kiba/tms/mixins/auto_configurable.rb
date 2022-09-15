# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Mixin module providing consistent methods for generating autoconfig
      #
      # ## Implementation details
      #
      # Modules mixing this in must:
      #
      # - `extend Tms::Mixins::AutoConfigurable`
      module AutoConfigurable
        include Tms::Mixins::Tableable

        def verify_empty_fields
          return nil unless used
          return Tms::Data::EmptyFieldsCheckerResult.new(status: :success, mod: self) if empty_fields.empty?

          Tms::Services::EmptyFieldsChecker.call(table, self)
        end
      end
    end
  end
end
