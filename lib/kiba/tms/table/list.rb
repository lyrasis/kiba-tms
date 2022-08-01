# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      class List
        class << self
          def call
            dirlist = Dir.new(Tms.tms_table_dir_path)
              .children
              .map{ |table| table.delete_suffix('.csv') }
              .reject{ |table| table['~lock.'] }
              .reject{ |table| table.match?(/\.(dat|hdr|txt|DS_Store)$/) }
            dirlist - empty_tables - Tms.excluded_tables
          end

          def as_filenames
            call.map{ |table| "#{table}.csv" }
          end
          
          private

          def empty_tables
            File.read(Tms.empty_table_list_path)
              .split("\n")
          end
        end
      end
    end
  end
end
