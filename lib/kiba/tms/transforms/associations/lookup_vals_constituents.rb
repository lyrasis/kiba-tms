# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Associations
        class LookupValsConstituents
          include Lookupable

          def initialize
            @lookup = Tms.get_lookup(
              jobkey: :constituents__early_lookup,
              column: :normid
            )
            @prefname = Tms::Constituents.preferred_name_field
            @connorm = Tms::Services::Names::ContypeNormalizer.new
          end

          private

          attr_reader :lookup, :prefname, :connorm

          def do_lookup(row, n)
            id = row["id#{n}".to_sym]
            return if id.blank?

            valfield = "val#{n}".to_sym
            typefield = "type#{n}".to_sym
            [valfield, typefield].each { |field| row[field] = nil }

            mergerows = lookup[id]
            return if mergerows.blank?

            row[valfield] = mergerows.map { |r| r[prefname] }
              .compact
              .join(Tms.delim)
            row[typefield] = mergerows.map { |r| r[:contype] }
              .compact
              .map { |val| connorm.call(val) }
              .join(Tms.delim)
          end
        end
      end
    end
  end
end
