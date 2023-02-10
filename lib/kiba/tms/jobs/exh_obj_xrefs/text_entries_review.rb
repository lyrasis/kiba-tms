# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhObjXrefs
        module TextEntriesReview
          module_function

          def job
            return unless Tms::TextEntries.for?(config.table_name)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__exh_obj_xrefs,
                destination: :exh_obj_xrefs__text_entries_review
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
              action: :keep,
              field: :text_entry
            transform Delete::FieldsExcept,
              fields: %i[objectnumber exhibitionnumber exhtitle objecttitle
                         text_entry]
            end
          end
        end
      end
    end
  end
end
