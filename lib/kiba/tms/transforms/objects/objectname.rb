# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class Objectname
          def initialize
            @target = :objectname
            @source_bases = set_source_bases
            @source_prefixes = set_source_prefixes
            @controlled = Tms::Objects.objectname_controlled
            @combiners = build_combiners
            @cleaner = Tms::Objects.objectname_controlled_cleaner.new
          end

          def process(row)
            combiners.each { |combiner| combiner.process(row) }
            return row unless controlled && cleaner

            cleaner.process(row)
            row
          end

          private

          attr_reader :target, :source_bases, :source_prefixes, :controlled,
            :combiners, :cleaner

          def set_source_bases
            base = [target]
            return base unless Tms::ObjectNames.used?

            [base, "objectnametype", "objectnamelanguage",
              "objectnamenote"].flatten
          end

          def set_source_prefixes
            return [] unless Tms::ObjectNames.used?

            %w[obj on]
          end

          def build_combiners
            return [] unless Tms::ObjectNames.used?

            source_bases.map { |base| base_combiner(base) }
          end

          def base_combiner(base)
            CombineValues::FromFieldsWithDelimiter.new(
              sources: base_source_fields(base),
              target: base.to_sym,
              delete_sources: true,
              delim: Tms.delim
            )
          end

          def base_source_fields(base)
            source_prefixes.map { |pre| "#{pre}_#{base}".to_sym }
          end
        end
      end
    end
  end
end
