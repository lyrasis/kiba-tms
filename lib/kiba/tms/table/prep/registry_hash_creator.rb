# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Prep
        # Convert table filename to prep registry hash
        class RegistryHashCreator
          def self.call(table_obj)
            self.new(table_obj).call
          end

          def initialize(table_obj)
            @table = table_obj
          end

          def call
            creator = merge_data(Tms::Table::Prep::CreatorGetter, table, :creator)
            return nil if creator.empty?

            basic_hash
              .merge(creator)
              .merge(merge_data(Tms::Table::Prep::LookupField, table.filekey, :lookup_on))
              .merge(merge_data(Tms::Table::Prep::DestinationOptions, table.filekey, :dest_special_opts))
              .merge(merge_data(Tms::Table::Prep::Tags, table.filekey, :tags))
          end

          private

          attr_reader :table

          def basic_hash
            {
              path: filepath
            }
          end

          def merge_data(klass, arg, key)
            result = klass.call(arg)
            return {} if result.nil?

            { key => result }
          end
          
          def filepath
            File.join(Tms.datadir, 'prepped', "#{table.filekey}.csv")
          end
        end
      end
    end
  end
end
