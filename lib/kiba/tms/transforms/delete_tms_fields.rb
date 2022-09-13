# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class DeleteTmsFields
        def initialize
          @fields = Tms.tms_fields
        end

        def process(row)
          @fields.each{ |field| row.delete(field) }
          row
        end
      end
    end
  end
end
