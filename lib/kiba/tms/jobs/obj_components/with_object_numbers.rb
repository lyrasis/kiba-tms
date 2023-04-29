# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module WithObjectNumbers
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_components,
                destination: :obj_components__with_object_numbers,
                lookup: %i[
                  objects__numbers_cleaned
                  objects__by_number
                ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              # merges in human-readable objectnumber
              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {
                  parentobjectnumber: :objectnumber,
                  parentname: :objectname,
                  parenttitle: :title,
                  parentdesc: :description
                },
                delim: Tms.delim
              # y if :componentnumber = :parentobjectnumber in same row
              transform Tms::Transforms::ObjComponents::FlagTopObjects
              # merge in temp field if :componentnumber = any existing :objectnumber
              transform Merge::MultiRowLookup,
                lookup: objects__by_number,
                keycolumn: :componentnumber,
                fieldmap: {
                  existingobject: :objectnumber
                },
                delim: Tms.delim
              # Removes :existingobject value altogether if row is for a top object, where it is expected to exist in
              #   Objects table
              # Changes remaining populated :existingobject values to 'y' to simplify
              transform do |row|
                exobj = row[:existingobject]
                next row if exobj.blank?

                istop = row[:is_top_object]
                row[:existingobject] = if istop.blank?
                  "y"
                end
                row
              end
              transform Deduplicate::FlagAll, on_field: :componentnumber,
                in_field: :duplicate, explicit_no: false

              # add :problemcomponent flag field for non-top-objects
              transform do |row|
                row[:problemcomponent] = nil
                istop = row[:is_top_object]
                next row unless istop.blank?

                vals = %i[existingobject duplicate].map { |field| row[field] }
                  .reject { |val| val.blank? }
                next row if vals.empty?

                row[:problemcomponent] = "y"
                row
              end
            end
          end
        end
      end
    end
  end
end
