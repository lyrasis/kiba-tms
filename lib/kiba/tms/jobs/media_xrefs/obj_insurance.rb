# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module ObjInsurance
          module_function

          def job
            return unless config.used?
            return unless config.for?('ObjInsurance')

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_xrefs_for__obj_insurance,
                destination: :media_xrefs__obj_insurance,
                lookup: %i[
                           media_files__id_lookup
                           valuation_control__all
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[mediamasterid id]
              # Break rule about L-t-R alphabetization of item types because
              #   we want all media :identificationnumber values in one column
              #   for lookup
              transform Merge::MultiRowLookup,
                lookup: valuation_control__all,
                keycolumn: :id,
                fieldmap: {item1_id: :valuationcontrolrefnumber}
              transform Merge::MultiRowLookup,
                lookup: media_files__id_lookup,
                keycolumn: :mediamasterid,
                fieldmap: {item2_id: :identificationnumber}
              transform Merge::ConstantValues, constantmap: {
                item1_type: 'valuationcontrols',
                item2_type: 'media',
              }
            end
          end
        end
      end
    end
  end
end
