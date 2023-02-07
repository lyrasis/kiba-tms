# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDeaccession
        module Shaped
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_deaccession,
                destination: :obj_deaccession__shaped
              },
              transformer: xforms
            )
          end

          def xforms
            bind =  binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)

              transform Delete::Fields, fields: :deaccessionid
              transform Tms::Transforms::DeleteTimestamps,
                fields: :entereddate
              transform Merge::ConstantValue,
                target: :exitreason,
                value: 'deaccession'
              transform Prepend::ToFieldValue,
                field: :estimatelow, value: 'Lowest estimated value: '
              transform Prepend::ToFieldValue,
                field: :estimatehigh, value: 'Highest estimated value: '
              transform Prepend::ToFieldValue,
                field: :proceedsrcvdisodate, value: 'Proceeds received: '
              transform Prepend::ToFieldValue,
                field: :reportisodate, value: 'Sale reported: '

              transform Rename::Fields, fieldmap: {
                entereddate: :exitdategroup,
                remarks: :exitnote,
                terms: :displosalprovisos,
                approvalisodate1: :authorizationdate,
                recipient_person: :disposalrecipientpersonlocal,
                recipient_org: :disposalrecipientorganizationlocal,
                netsaleamount: :displosalvalue,
                saleisodate: :deaccessiondate
              }

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[estimatelow estimatehigh proceedsrcvdisodate
                            reportisodate],
                target: :displosalnote,
                sep: '%CR%',
                delete_sources: true
            end
          end
        end
      end
    end
  end
end
