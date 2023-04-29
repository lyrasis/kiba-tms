# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ParentDescMismatch
          module_function

          def job
            return unless config.used?
            return unless config.actual_components

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__actual_components,
                destination: :obj_components__parent_desc_mismatch,
                lookup: %i[
                           objects__numbers_cleaned
                           prep__objects
                           ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[componentnumber objectid physdesc]
              transform Rename::Fields, fieldmap: {
                physdesc: :componentdesc
              }
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :componentdesc

              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {parentnumber: :objectnumber}

              transform Merge::MultiRowLookup,
                lookup: prep__objects,
                keycolumn: :parentnumber,
                fieldmap: {
                  parentdesc: :description
                }

              transform do |row|
                compdesc = row[:componentdesc].downcase
                pdesc = row[:parentdesc]
                next row if pdesc.blank?

                next if pdesc[compdesc] || compdesc[pdesc]
                row
              end

              transform Delete::Fields,
                fields: %i[objectid]
            end
          end
        end
      end
    end
  end
end
