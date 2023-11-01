# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Associations
        # Merges human-readable values for ids into rows
        class LookupVals
          def initialize(tablefield: :tablename)
            @tablefield = tablefield
            @processors = set_up_processors
          end

          def process(row)
            [1, 2].each do |n|
              row["val#{n}".to_sym] = nil
              row["type#{n}".to_sym] = nil
            end
            table = row[tablefield]
            processors[table].process(row) if processors.key?(table)
            row
          end

          private

          attr_reader :tablefield, :processors, :prefname

          def set_up_processors
            Tms::Associations.target_tables
              .map { |table| set_up_processor(table) }
              .to_h
              .compact
          end

          def set_up_processor(table)
            xform = Tms::Transforms::Associations.const_get(
              "LookupVals#{table}"
            ).new
          rescue
            warn(
              "WARNING: No Tms::Transforms::Associations::LookupVals#{table} "\
                "transform"
            )
            [table, nil]
          else
            [table, xform]
          end

          def do_lookups(row)
            [1, 2].each { |n| do_lookup(row, n) }
          end
        end
      end
    end
  end
end
