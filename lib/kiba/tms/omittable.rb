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
    # - define `empty_fields` setting (Array)
    # - `extend Tms::Omittable`
    module Omittable
      def delete_omitted_fields(hash)
        omitted_fields.each{ |field| hash.delete(field) if hash.key?(field) }
        hash
      end
      
      def omitted_fields
        ( delete_fields + empty_fields ).uniq
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
