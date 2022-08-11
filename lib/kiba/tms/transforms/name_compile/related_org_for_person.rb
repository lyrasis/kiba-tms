# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class RelatedOrgForPerson
          def initialize(target:)
            @target = target
            @name = Tms::Constituents.preferred_name_field
          end

          # @private
          def process(row)
            build_rows(row).each{ |row| yield row }
            nil
          end
          
          private

          attr_reader :target, :name

          def add_shared_fields(row, fields)
            (fields - row.keys).each{ |field| row[field] = nil }
            row
          end
          
          def build_rows(row)
            initial = [org_name_row(row.dup), org_rel_name_row(row.dup)]
            fields = initial.map{ |irow| irow.keys }.flatten.uniq
            initial.map{ |irow| add_shared_fields(irow, fields) }
          end

          def org_name_row(row)
            row[:contype] = 'Organization'
            row[name] = row[:institution]
            row[:relation_type] = 'main term'
            [Tms::NameCompile.org_nil, Tms::NameCompile.related_nil].flatten.each{ |field| row.delete(field) }
            row
          end

          def org_rel_name_row(row)
            row[:contype] = 'Organization'
            row[:related_term] = row[name]
            row[name] = row[:institution]
            row[:relation_type] = target
            row[:related_role] = row[:position]
            [Tms::NameCompile.org_nil, Tms::NameCompile.related_nil].flatten.each{ |field| row.delete(field) }
            row
          end
        end
      end
    end
  end
end
