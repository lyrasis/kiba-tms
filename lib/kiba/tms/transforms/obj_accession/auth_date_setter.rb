# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjAccession
        class AuthDateSetter
          def initialize
            @fields = Tms::ObjAccession.auth_date_source_pref
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
            @target = :acquisitionauthorizerdate
          end

          def process(row)
            row[target] = nil
            valhash = getter.call(row)
            return row if valhash.empty?

            usefield = valhash.keys.first
            row[target] = valhash[usefield]
            row[usefield] = nil
            row
          end

          private

          attr_reader :fields, :getter, :target
        end
      end
    end
  end
end
