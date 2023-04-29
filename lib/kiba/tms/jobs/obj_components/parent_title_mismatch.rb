# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module ParentTitleMismatch
          module_function

          def job
            return unless config.used?
            return unless config.actual_components

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__actual_components,
                destination: :obj_components__parent_title_mismatch,
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
                fields: %i[componentnumber objectid title]
              transform Rename::Fields, fieldmap: {
                title: :componenttitle
              }
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :componenttitle

              transform Merge::MultiRowLookup,
                lookup: objects__numbers_cleaned,
                keycolumn: :objectid,
                fieldmap: {parentnumber: :objectnumber}

              transform Merge::MultiRowLookup,
                lookup: prep__objects,
                keycolumn: :parentnumber,
                fieldmap: {
                  parentobjectname: :objectname,
                  parenttitle: :title
                }

              transform do |row|
                row[:inname] = nil
                row[:intitle] = nil

                comptitle = row[:componenttitle].downcase
                pname = row[:parentobjectname]
                unless pname.blank?
                  row[:inname] = "n" unless pname.downcase[comptitle]
                end
                ptitle = row[:parenttitle]
                unless ptitle.blank?
                  row[:intitle] = "n" unless ptitle.downcase[comptitle]
                end
                row
              end

              transform FilterRows::AllFieldsPopulated,
                action: :keep,
                fields: %i[inname intitle]
              transform Delete::Fields,
                fields: %i[objectid inname intitle]
            end
          end
        end
      end
    end
  end
end
