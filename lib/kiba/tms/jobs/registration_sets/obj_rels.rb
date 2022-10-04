# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module RegistrationSets
        module ObjRels
          module_function

          def job
            return unless config.used?
            return unless Tms::ObjAccession.processing_approaches.any?(
              :linkedlot
            )
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_accession__linked_lot,
                destination: :registration_sets__obj_rels,
                lookup: %i[
                           prep__registration_sets
                           tms__objects
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[registrationsetid objectid]
              transform Merge::MultiRowLookup,
                lookup: prep__registration_sets,
                keycolumn: :registrationsetid,
                fieldmap: {item1_id: :acquisitionreferencenumber}
              transform Merge::MultiRowLookup,
                lookup: tms__objects,
                keycolumn: :objectid,
                fieldmap: {item2_id: :objectnumber}
              transform Merge::ConstantValues,
                constantmap: {
                  item1_type: 'acquisitions',
                  item2_type: 'collectionobjects'
                }
              transform Delete::Fields,
                fields: %i[registrationsetid objectid]
            end
          end
        end
      end
    end
  end
end
