# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module TextEntries
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__text_entries,
                destination: :prep__text_entries,
                lookup: %i[
                           nameclean__by_constituentid
                           prep__text_types
                           ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform FilterRows::FieldEqualTo, action: :reject, field: :objectid, value: '-1'

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[purpose remarks textentry],
                target: :combined,
                sep: ' ',
                delete_sources: false
              transform FilterRows::FieldPopulated, action: :keep, field: :combined
              transform Delete::Fields, fields: :combined
              
              transform Delete::EmptyFields, consider_blank: {textstatusid: '0'}
              transform Delete::Fields, fields: %i[textentryhtml languageid]



              transform Rename::Fields, fieldmap: {
                id: :tablerowid,
                textentryid: :sort
              }
              transform Tms::Transforms::TmsTableNames
              transform Merge::MultiRowLookup,
                lookup: prep__text_types,
                keycolumn: :texttypeid,
                fieldmap: { texttype: :texttype }
              transform Delete::Fields, fields: :texttypeid

              org_cond = ->(_x, rows){ rows.reject{ |row| row[:org].blank? } }
              transform Merge::MultiRowLookup,
                lookup: nameclean__by_constituentid,
                keycolumn: :authorconid,
                fieldmap: { org_author: Tms::Constituents.preferred_name_field },
                conditions: org_cond

              person_cond = ->(_x, rows){ rows.reject{ |row| row[:person].blank? } }
              transform Merge::MultiRowLookup,
                lookup: nameclean__by_constituentid,
                keycolumn: :authorconid,
                fieldmap: { person_author: Tms::Constituents.preferred_name_field },
                conditions: person_cond
              transform Delete::Fields, fields: :authorconid

              if Tms.data_cleaner
                transform Tms.data_cleaner
              end
            end
          end
        end
      end
    end
  end
end
