# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class TmsTableNames
        def initialize(source: :tableid, target: :tablename)
          @source = source
          @target = target
          @lookup = Tms.table_lookup
        end

        def process(row)
          row[@target] = nil
          tid = row.fetch(@source, nil)
          row.delete(@source)
          return row if tid.blank?

          row[@target] = table_name(tid)
          row
        end

        private

        def table_name(id)
          unless @lookup.key?(id)
            puts "#{Kiba::Extend.warning_label}: ID #{id} is not in #{self.class} lookup"
            return nil
          end

          @lookup[id]
        end
      end
    end
  end
end
