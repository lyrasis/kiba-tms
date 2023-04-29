# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module CondLineItems
        module Prep
          module_function

          def desc
            "- Deletes TMS fields\n"\
              "- Delete config empty and deleted fields\n"\
              "- \n"\
          end

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__cond_line_items,
                destination: :prep__cond_line_items,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[]
            base << :prep__survey_attr_types if Tms::SurveyAttrTypes.used
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              if lookups.any?(:prep__survey_attr_types)
                transform Merge::MultiRowLookup,
                  lookup: prep__survey_attr_types,
                  keycolumn: :attributetypeid,
                  fieldmap: {attributetype: :attributetype}
              end
              transform Delete::Fields, fields: :attributetypeid
            end
          end
        end
      end
    end
  end
end
