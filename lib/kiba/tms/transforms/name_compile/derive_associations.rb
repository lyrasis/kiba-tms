# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class DeriveAssociations
          def initialize
            #            @rows = []
            @treatments = Tms::Associations.type_treatments["Constituents"]
          end

          def process(row)
            reltype = row[:relationtype]
            return if reltype.blank?

            xform = treatments[reltype]
            return unless xform

            xform.process(row) { |r| yield r }
            nil
          end

          # def close
          #   rows.each{ |row| yield row }
          # end

          private

          attr_reader :rows, :treatments

          Name = Struct.new("Name", :name, :type, :side, :id, :rel)

          def extract_names_by_side(row)
            [1, 2].map { |side| extract_side(side, row) }
              .flatten
              .group_by { |name| name.side }
          end

          def extract_side(side, row)
            id = build_id(side, row)
            names = row["val#{side}".to_sym].split(Tms.delim)
            types = row["type#{side}".to_sym].split(Tms.delim)
            rel = row["rel#{side}".to_sym]
            names.map.with_index do |name, idx|
              Name.new(name, types[idx], side, id, rel)
            end
          end

          def build_id(side, row)
            associd = row[:associationid]
            conid = row["id#{side}".to_sym]
            varid = row["id#{other(side)}".to_sym]
            "Assoc#{associd}.#{conid}.#{varid}"
          end

          def other(side)
            case side
            when 1 then 2
            when 2 then 1
            end
          end
        end
      end
    end
  end
end
