# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module RegistrationSets
        module Prep
          module_function

          def job
            return unless config.used?
            return unless Tms::ObjAccession.processing_approaches.any?(
              :linkedset
            )
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__registration_sets,
                destination: :prep__registration_sets,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[prep__accession_lot]
            base << :prep__accession_methods if Tms::AccessionMethods.used?
            base << :prep__object_statuses if Tms::ObjectStatuses.used?
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if Tms::AccessionMethods.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__accession_methods,
                  keycolumn: :accessionmethodid,
                  fieldmap: {Tms::AccessionMethods.type_field =>
                             Tms::AccessionMethods.type_field}
              end
              if Tms::ObjectStatuses.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__object_statuses,
                  keycolumn: :objectstatusid,
                  fieldmap: {Tms::ObjectStatuses.type_field =>
                             Tms::ObjectStatuses.type_field}
              end


              transform Delete::Fields,
                fields: %i[accessionmethodid objectstatusid lotid]

              if Tms::ConRefs.for?('RegistrationSets')
                transform Tms::Transforms::ConRefs::Merger,
                  into: config,
                  keycolumn: :registrationsetid
              end
            end
          end
        end
      end
    end
  end
end
