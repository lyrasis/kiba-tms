# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjAccession
        class InitiationNote
          def initialize
            @fields = %i[initiator initdate]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
            @target = :initiation_note
          end

          def process(row)
            row[target] = nil

            vals = getter.call(row).values
            unless vals.empty?
              row[target] = "Initiated: #{vals.join(', ')}"
            end

            fields.each{ |f| row.delete(f) if row.key?(f) }
            row
          end

          private

          attr_reader :fields, :getter, :target
        end
      end
    end
  end
end
