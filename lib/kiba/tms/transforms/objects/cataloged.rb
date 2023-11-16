# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class Cataloged
          def initialize
            @mapping = {
              cataloguer: :cat_annotationauthor,
              catalogueisodate: :cat_annotationdate
            }
            @renamer = Rename::Fields.new(fieldmap: mapping)
            @typefield = :cat_annotationtype
            @typevalue = "cataloged"
          end

          def process(row)
            renamer.process(row)
            row[typefield] = nil
            return row unless eligible?(row)

            row[typefield] = typevalue
            row
          end

          private

          attr_reader :mapping, :renamer, :typefield, :typevalue

          def eligible?(row)
            mapping.values
              .map { |field| row[field] }
              .reject(&:blank?)
              .length
              .> 0
          end
        end
      end
    end
  end
end
