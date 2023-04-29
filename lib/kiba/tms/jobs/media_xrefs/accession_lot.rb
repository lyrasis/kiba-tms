# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaXrefs
        module AccessionLot
          module_function

          def job
            return unless config.used?
            return unless config.for?("AccessionLot")

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_xrefs_for__accession_lot,
                destination: :media_xrefs__accession_lot,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = [:media_files__id_lookup]
            if Tms::ObjAccession.processing_approaches.any?(:linkedlot)
              warn("MediaXrefs::AccessionLot needs a lookup!")
            end
            if Tms::ObjAccession.processing_approaches.any?(:linkedset)
              base << :linked_set_acq__prep
            end
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              lookups = job.send(:lookups)

              transform Delete::FieldsExcept,
                fields: %i[mediamasterid id]

              # Here is where we need to lookup :item1_id_lot from currently
              #   nonexistent linkedlot lookup table

              if lookups.any?(:linked_set_acq__prep)
              transform Merge::MultiRowLookup,
                lookup: Tms.get_lookup(
                  jobkey: :tms__registration_sets,
                  column: :lotid
                  ),
                keycolumn: :id,
                fieldmap: {setid: :registrationsetid}
              transform Merge::MultiRowLookup,
                lookup: linked_set_acq__prep,
                keycolumn: :setid,
                fieldmap: {item1_id_set: :acquisitionreferencenumber}
              transform Delete::Fields, fields: :setid
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[item1_id_lot item1_id_set],
                target: :item1_id,
                sep: "",
                delete_sources: true

              transform Merge::MultiRowLookup,
                lookup: media_files__id_lookup,
                keycolumn: :mediamasterid,
                fieldmap: {item2_id: :identificationnumber}
              transform Merge::ConstantValues, constantmap: {
                item1_type: "acquisitions",
                item2_type: "media"
              }
            end
          end
        end
      end
    end
  end
end
