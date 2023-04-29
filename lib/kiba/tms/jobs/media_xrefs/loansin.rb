# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module Loansin
          module_function

          def job
            return unless config.used?
            return unless config.for?("Loans")

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_xrefs_for__loans,
                destination: :media_xrefs__loansin,
                lookup: %i[
                  media_files__id_lookup
                  tms__loans
                ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :loanin
              transform Delete::FieldsExcept,
                fields: %i[mediamasterid id]
              transform Merge::MultiRowLookup,
                lookup: tms__loans,
                keycolumn: :id,
                fieldmap: {item1_id: :loannumber}
              transform Merge::MultiRowLookup,
                lookup: media_files__id_lookup,
                keycolumn: :mediamasterid,
                fieldmap: {item2_id: :identificationnumber}
              transform Merge::ConstantValues, constantmap: {
                item1_type: "loansin",
                item2_type: "media"
              }
            end
          end
        end
      end
    end
  end
end
