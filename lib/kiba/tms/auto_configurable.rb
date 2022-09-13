# frozen_string_literal: true

module Kiba
  module Tms
    # Mixin module providing consistent methods for generating autoconfig
    #
    # ## Implementation details
    #
    # Modules mixing this in must:
    #
    # - `extend Tms::AutoConfigurable`
    module AutoConfigurable
      include Tms::Omittable
      include Tms::Tableable

      
      def verify_empty_fields
        return nil unless used
        return Tms::Data::EmptyFieldsCheckerResult.new(status: :success, mod: self) if empty_fields.empty?

        Tms::Services::EmptyFieldsChecker.call(table, self)
      end

#      private_class_method %i[verify_empty_fields]
    end
  end
end
