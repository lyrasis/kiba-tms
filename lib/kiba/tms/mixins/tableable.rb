# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Mixins
      # Mixin module providing consistent methods for accessing the db table for a config module
      #
      # ## Implementation details
      #
      # Modules mixing this in must:
      #
      # - name match a TMS table filename
      # - `extend Tms::Mixins::Tableable`
      module Tableable        
        def all_fields
          return [] unless used
          
          CSV.foreach(table.supplied_data_path)
            .first
            .map(&:downcase)
            .map(&:to_sym)
        end

        def fields
          return [] if all_fields.empty?

          all_fields - Tms.tms_fields - delete_fields - empty_fields
        end

        def filekey
          return nil unless used?

          table.filekey
        end

        def table
          Tms::Table::Obj.new(table_name)
        end

        def table_name
          name.split('::').last
        end

        # whether or not table is used in client migration project
        def used
          used?
        end

        def used?
          Tms::Table::List.include?(table_name)
        end
      end
    end
  end
end
