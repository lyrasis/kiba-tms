# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      class List
        class << self
          def all
            from_dir + empty_tables + Tms.excluded_tables
          end

          def as_filenames
            call.map{ |table| "#{table}.csv" }
          end

          def call
            used
          end

          def include?(tablename)
            used.any?(tablename)
          end

          def used
            from_dir - empty_tables - Tms.excluded_tables
          end

          private
          def from_dir
            Dir.new(Tms.tms_table_dir_path)
              .children
              .map{ |table| table.delete_suffix(".csv") }
              .reject{ |table| table["~lock."] }
              .reject{ |table| table.match?(/\.(dat|hdr|txt|DS_Store)$/) }
          end

          def empty_tables
            path = Tms.empty_table_list_path
            return [] unless File.exist?(path)

            File.read(path)
              .split("\n")
          end
        end
      end
    end
  end
end
