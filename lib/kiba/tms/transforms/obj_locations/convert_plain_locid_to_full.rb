# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class ConvertPlainLocidToFull
          def initialize(fields:)
            @fields = [fields].flatten
            @placeholder = Tms::ObjLocations.fulllocid_placeholder
            @delim = Tms.delim
            @suffix_ct = Tms::ObjLocations.fulllocid_fields.length + 1
          end

          def process(row)
            fields.each do |field|
              fieldval = row[field]
              next if fieldval.blank?

              row[field] = convert(fieldval)
            end
            row
          end

          private

          attr_reader :fields, :placeholder, :delim, :suffix_ct

          def convert(val)
            base = [val]
            suffix_ct.times { base << placeholder }
            base.join(delim)
          end
        end
      end
    end
  end
end
