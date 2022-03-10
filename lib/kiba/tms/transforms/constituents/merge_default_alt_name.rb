# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class MergeDefaultAltName
          include Kiba::Extend::Transforms::Helpers

          def initialize(alt_names:)
            @name = Kiba::Tms.config.constituents.preferred_name_field
            @alt_name = "alt_#{name}".to_sym
            @alt_names = alt_names
          end

          def process(row)
            row[alt_name] = nil
            
            did = row.fetch(:defaultnameid, nil).dup
            row.delete(:defaultnameid)
            return row if did.blank?

            vals = alt_names.fetch(did, nil)
            return row if vals.blank?

            val = vals.first
            row[alt_name] = val[name]
            
            row
          end

          private

          attr_reader :name, :alt_name, :alt_names
        end
      end
    end
  end
end
