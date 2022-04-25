# frozen_string_literal: true

module Kiba
  module Tms
    module Table
      module Supplied
        # Convert table filename to registry hash
        class RegistryHashCreator
          def self.call(table_obj)
            self.new(table_obj).call
          end

          def initialize(table_obj)
            @table = table_obj
          end

          def call
            basic_hash.merge(lookup_hash)
          end

          private

          attr_reader :table

          def basic_hash
            {
              path: filepath,
              supplied: true
            }
          end
          
          def filepath
            File.join(Tms.datadir, 'tms', table.filename)
          end

          def lookup_hash
            lookup_field = Tms::Table::Supplied::LookupField.call(table.filekey)
            return {} if lookup_field.nil?

            { lookup_on: lookup_field }
          end
         end
      end
    end
  end
end
