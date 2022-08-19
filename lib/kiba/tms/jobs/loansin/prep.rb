# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Loansin
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :loans__in,
                destination: :loansin__prep
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Rename::Fields, fieldmap: {
                loannumber: :loaninnumber
              }

              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: {
                  requestdate: :req_loanstatusdate,
                  requestedby: :req_loanindividual
                },
                constant_target: :req_loanstatus,
                constant_value: 'Requested'

              transform Reshape::FieldsToFieldGroupWithConstant,
                fieldmap: {
                  approveddate: :app_loanstatusdate,
                  approvedby: :app_loanindividual
                },
                constant_target: :app_loanstatus,
                constant_value: 'Approved'

              if Tms::Loansin.remarks_treatment == :statusnote
                transform Tms::Transforms::Loansin::RemarksToStatusNote
              elsif Tms::Loansin.remarks_treatment == :note
                Tms::Loansin.loaninnote_source_fields << :remarks
              end

              transform Collapse::FieldsToRepeatableFieldGroup,
                sources: Tms::Loansin.status_sources,
                targets: Tms::Loansin.status_targets,
                delim: Tms.delim

              notefields = Tms::Loansin.loaninnote_source_fields
              unless notefields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: notefields,
                  target: :loaninnote,
                  sep: '%CR%%CR%',
                  delete_sources: true
              end

              conditionsfields = Tms::Loansin.loaninconditions_source_fields
              unless conditionsfields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: notefields,
                  target: :loaninconditions,
                  sep: '%CR%%CR%',
                  delete_sources: true
              end
            end
          end
        end
      end
    end
  end
end
