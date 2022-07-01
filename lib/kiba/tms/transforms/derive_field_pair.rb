# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class DeriveFieldPair
        def initialize(source:, newfield:, value:, sourcebecomes:)
          @source = source
          @newfield = "#{source}_#{newfield}".to_sym
          @value = value
          @sourcebecomes = "#{source}_#{sourcebecomes}".to_sym
        end

        def process(row)
          val = row[source]
          if val.blank?
            row[newfield] = '%NULLVALUE%'
            row[sourcebecomes] = '%NULLVALUE%'
          else
            row[newfield] = value
            row[sourcebecomes] = val
          end
          row.delete(source)

          row
        end

        private

        attr_reader :source, :newfield, :value, :sourcebecomes
      end
    end
  end
end

