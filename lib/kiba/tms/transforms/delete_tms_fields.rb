# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class DeleteTmsFields
        def initialize(except: [])
          @fields = Tms.tms_fields - [except].flatten
        end

        def process(row)
          @fields.each{ |field| row.delete(field) }
          row
        end
      end
    end
  end
end
