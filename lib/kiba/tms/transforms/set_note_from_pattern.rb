# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class SetNoteFromPattern
        include Kiba::Extend::Transforms::Helpers

        def initialize(fields:, patterns:, target:)
          @patterns = patterns
          @target = target
          @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
            fields: fields
          )
        end

        def process(row)
          row[target] = nil
          eligible = getter.call(row).map{ |field, val|
            matching = patterns.select{ |pattern| pattern.match?(val) }
            if matching.empty?
              nil
            else
              [field, get_terms(matching, val)]
            end
          }.compact
            .to_h
          return row if eligible.empty?

          row[target] = eligible.to_s

          row
        end

        private

        attr_reader :patterns, :getter, :target

        def get_terms(matching, val)
          matching.map{ |pattern, term|
            if term == "patternmatch"
              val.match(pattern)
                .to_s
                .strip
            else
              term
            end
          }.uniq
        end
      end
    end
  end
end
