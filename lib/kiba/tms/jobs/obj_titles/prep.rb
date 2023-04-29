# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjTitles
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_titles,
                destination: :prep__obj_titles,
                lookup: %i[
                           prep__title_types
                           prep__dd_languages
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              unless Tms::ObjTitles.migrate_inactive
                transform FilterRows::FieldEqualTo, action: :keep, field: :active, value: "1"
              end
              transform Delete::Fields, fields: :active

              transform Tms.data_cleaner if Tms.data_cleaner

              transform Merge::MultiRowLookup,
                lookup: prep__title_types,
                keycolumn: :titletypeid,
                fieldmap: {titletype: :titletype}
              transform Delete::Fields, fields: :titletypeid

              transform Merge::MultiRowLookup,
                lookup: prep__dd_languages,
                keycolumn: :languageid,
                fieldmap: {language: :language}
              transform Delete::Fields, fields: :languageid

              if Tms::ObjTitles.note_creator
                transform Tms::ObjTitles.note_creator
              end
            end
          end
        end
      end
    end
  end
end
