# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module NhrReport
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__id_lookup,
                destination: :media_files__nhr_report,
                lookup: :media_xrefs__nhrs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept, fields: :identificationnumber

              transform Count::MatchingRowsInLookup,
                lookup: media_xrefs__nhrs,
                keycolumn: :identificationnumber,
                targetfield: :relationship_ct
              transform Merge::MultiRowLookup,
                lookup: media_xrefs__nhrs,
                keycolumn: :identificationnumber,
                fieldmap: {
                  related_id: :item1_id,
                  related_type: :item1_type
                },
                delim: Tms.delim
            end
          end
        end
      end
    end
  end
end
