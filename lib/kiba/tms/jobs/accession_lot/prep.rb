# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AccessionLot
        module Prep
          module_function

          def job
            return unless config.used?
            approaches = Tms::ObjAccession.processing_approaches
            return unless approaches.any?(:linkedlot) ||
              approaches.any?(:linkedset)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__accession_lot,
                destination: :prep__accession_lot
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

              transform Tms.data_cleaner if Tms.data_cleaner

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :lotcount,
                find: "^0$",
                replace: ""

              if Tms::ConRefs.for?("AccessionLot")
                transform Tms::Transforms::ConRefs::Merger,
                  into: config,
                  keycolumn: :acquisitionlotid
              end
            end
          end
        end
      end
    end
  end
end
