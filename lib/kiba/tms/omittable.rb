# frozen_string_literal: true

module Kiba
  module Tms
    # Mixin module providing consistent methods for deriving omittable fields
    #
    # ## Implementation details
    #
    # Modules mixing this in must:
    #
    # - `extend Dry::Configurable`
    # - define `delete_fields` setting (Array)
    # - define `empty_fields` setting (Hash (Array supported for backwards compatibility))
    # - `extend Tms::Omittable`
    module Omittable
      def delete_omitted_fields(hash)
        omitted_fields.each{ |field| hash.delete(field) if hash.key?(field) }
        hash
      end

      def emptyfields
        return [] unless empty_fields

        case empty_fields.class
        when Array
          empty_fields
        when Hash
          empty_fields.keys
        end
      end
      
      def omitted_fields
        ( delete_fields + emptyfields ).uniq
      end

      def omitting_fields?
        true unless omitted_fields.empty?
      end

      def subtract_omitted_fields(arr)
        arr - omitted_fields
      end
    end
  end
end
