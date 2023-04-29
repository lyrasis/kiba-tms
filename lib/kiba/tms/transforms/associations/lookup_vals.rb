# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Associations
        # Merges human-readable values for ids 1 & 2 into row
        class LookupVals
          include Kiba::Extend::Transforms::SingleWarnable

          def initialize(con_lookup: nil,
                         obj_lookup: nil,
                         tablefield: :tablename
                        )
            @con_lookup = con_lookup
            @obj_lookup = obj_lookup
            @tablefield = tablefield
            @prefname = :prefname
            setup_single_warning
          end

          # @private
          def process(row)
            [1, 2].each do |n|
              target = "val#{n}".to_sym
              row[target] = nil
              idval = row["id#{n}".to_sym]
              next if idval.blank?

              do_lookup(idval, target, row)
            end

            row
          end

          private

          attr_reader :con_lookup, :obj_lookup, :tablefield, :prefname

          def do_lookup(id, target, row)
            case row[tablefield]
            when "Constituents"
              lookup_con(id, target, row)
            when "Objects"
              lookup_obj(id, target, row)
            else
              add_single_warning("#{self.class.name}: Unhandled table")
            end
          end

          def lookup_con(id, target, row)
            matches = con_lookup[id]
            return if matches.blank?

            row[target] = matches.first[prefname]
          end

          def lookup_obj(id, target, row)
            matches = obj_lookup[id]
            return if matches.blank?

            row[target] = matches.first[:objectnumber]
          end
        end
      end
    end
  end
end
