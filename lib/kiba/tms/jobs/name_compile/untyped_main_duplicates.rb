# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module UntypedMainDuplicates
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__raw,
                destination: :name_compile__untyped_main_duplicates,
                lookup: :name_compile__raw
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated, action: :reject, field: :contype
              transform FilterRows::FieldEqualTo, action: :keep, field: :relation_type, value: '_main term'
              
              transform Delete::FieldsExcept, fields: %i[fingerprint norm]
              transform Deduplicate::Flag, on_field: :norm, in_field: :duplicate_self,
                using: {}, explicit_no: false
              
              transform Merge::MultiRowLookup,
                lookup: name_compile__raw,
                keycolumn: :norm,
                fieldmap: {typed: :contype},
                constantmap: {duplicate_typed: 'y'},
                conditions: ->(this, those) do
                  those.select{ |row| !row[:contype].blank? && row[:relation_type] == '_main term' }
                end
              transform Append::NilFields, fields: :duplicate_all

              transform do |row|
                row[:duplicate] = nil
                ds = row[:duplicate_self]
                row[:duplicate] = 'y' if ds && ds == 'y'
                next row if row[:duplicate]

                dt = row[:duplicate_typed]
                row[:duplicate] = 'y' if dt && !dt.blank?

                row
              end
              
              transform Delete::FieldsExcept, fields: %i[fingerprint duplicate_all duplicate]
              transform FilterRows::FieldPopulated, action: :keep, field: :duplicate
            end
          end
        end
      end
    end
  end
end
