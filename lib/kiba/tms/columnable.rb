# frozen_string_literal: true

module Kiba
  module Tms
    # ## Implementation details
    #
    # Modules/classes mixing this in must define:
    #
    # - `:mod` method/instance variable returning Module constant name
    # - the module referred to in `:mod` must define a `:used_in` setting
    module Columnable
      def process_used_in
        cols = mod.used_in
        return nil if cols.empty?

        result = {}
        
        cols.each do |col|
          val = col.split('.')
          table = Tms::Table::Obj.new(val[0])
          next unless table.used?
          
          path = table.supplied_data_path
          field = val[1].to_sym
          result[col] = [path, field]
        end

        result
      end
    end
  end
end
