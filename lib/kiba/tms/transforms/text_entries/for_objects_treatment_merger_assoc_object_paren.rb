# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        ObjType = Struct.new("ObjType", :obj, :type)

        class ForObjectsTreatmentMergerAssocObjectParen
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @objtarget = :te_assocobject
            @typetarget = :te_assocobjecttype
            @notetarget = :te_assocobjectnote
            @delim = Tms.delim
          end

          def process(row, mergerow)
            note = derive_note(mergerow)

            split_obj_type(mergerow).each do |ot|
              obj = ot.obj.blank? ? "%NULLVALUE%" : ot.obj
              type = ot.type.blank? ? "%NULLVALUE%" : ot.type
              append_value(row, objtarget, obj, delim)
              append_value(row, typetarget, type, delim)
              append_value(row, notetarget, note, delim)
            end
            row
          end

          private

          attr_reader :objtarget, :typetarget, :notetarget, :delim

          def get_value(field, mergerow)
            val = mergerow[field]
            val.blank? ? "%NULLVALUE%" : val
          end

          def derive_note(mergerow)
            parts = [
              mergerow[:authorname],
              mergerow[:textdate]
            ].reject(&:blank?)
            parts.empty? ? "%NULLVALUE%" : parts.join(", ")
          end

          def split_obj_type(mergerow)
            val = mergerow[:textentry]
            if val.match?(/\(.*\)/)
              val.split(")").map { |segment| split_paren_pair(segment) }
            elsif val.match?(/\([^)0-9]+$/)
              [split_paren_pair(val)]
            elsif val.downcase.start_with?("variant", "duplicate")
              split_from_start(val)
            else
              [ObjType.new(val, "%NULLVALUE%")]
            end
          end

          def split_paren_pair(segment)
            vals = segment.split(/ *\(/)
            ObjType.new(vals[0], vals[1])
          end

          def split_from_start(val)
            parts = val.match(
              /((?:[Dd]uplicate|[Vv]ariant)s?)(?: *- *| *: *|, *| +)(.*)/
            )
            [ObjType.new(parts[2], parts[1])]
          end
        end
      end
    end
  end
end
