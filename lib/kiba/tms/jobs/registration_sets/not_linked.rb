# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module RegistrationSets
        module NotLinked
          module_function

          def job
            return unless config.used?
            return unless Tms::ObjAccession.processing_approaches.any?(
              :linkedset
            )
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__registration_sets,
                destination: :registration_sets__not_linked
              },
              transformer: xforms
            )
          end

          def lookup
            reg = Tms.registry.resolve(:tms__obj_accession)
            path = reg.path
            Kiba::Extend::Utils::Lookup.csv_to_hash(
              file: path,
              keycolumn: :registrationsetid
            )

          end

          def xforms
            bind = binding

            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: bind.receiver.send(:lookup),
                keycolumn: :registrationsetid,
                fieldmap: {objs: :objectid},
                delim: Tms.delim
              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :objs
              transform Delete::Fields, fields: :objs
            end
          end
        end
      end
    end
  end
end
