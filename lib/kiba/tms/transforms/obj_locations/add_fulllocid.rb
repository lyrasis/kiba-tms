# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class AddFulllocid
          def initialize(mode: :hier)
            @target = :fulllocid
            @fields = set_fields(mode)
            @placeholder = 'nil'
            @delim = Tms.delim
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields,
              discard: []
            )
            @ttgetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: tt_fields
            )
          end

          def process(row)
            locid = row[:locationid]
            tt = tt_val(row)
            vals = field_vals(row)
            row[target] = [locid, tt, vals].join(delim)
              .delete_suffix(Tms.delim)
            row
          end

          private

          attr_reader :target, :fields, :temp_fields, :placeholder, :delim,
            :getter, :ttgetter

          def field_vals(row)
            getter.call(row)
              .values
              .map{ |val| val.blank? ? 'nil' : val }
              .join(delim)
          end

          def set_fields(mode)
            if mode == :hier
              Tms::ObjLocations.fulllocid_fields_hier
            else
              Tms::ObjLocations.fulllocid_fields
            end
          end

          def tt_fields
            return [] if Tms::ObjLocations.fulllocid_fields.none?(:temptext)
            return [:temptext] unless Tms::ObjLocations.temptext_mapping_done

            Tms::ObjLocations.temptext_target_fields
          end

          def tt_val(row)
            results = ttgetter.call(row)
              .values
            return 'nil' if results.blank?

            result = results.first
            return 'nil' if result.blank?

            result
          end
        end
      end
    end
  end
end
