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
              :linkedlot
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
            if Tms::ConRefs.for?('RegistrationSets')
              base << :con_refs_for__registration_sets
            end
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

              fmap = Tms::AccessionLot.content_fields.map do |field|
                [field, field]
              end.to_h

              transform Merge::MultiRowLookup,
                lookup: prep__accession_lot,
                keycolumn: :lotid,
                fieldmap: fmap

              transform Delete::Fields,
                fields: %i[accessionmethodid objectstatusid lotid]

              owners = config.con_role_treatment_mappings[:owner]
              if Tms::ConRefs.for?('RegistrationSets')
                unless owners.blank?
                  transform Merge::MultiRowLookup,
                    lookup: con_refs_for__registration_sets,
                    keycolumn: :registrationsetid,
                    fieldmap: {ownerpersonlocal: :person},
                    conditions: ->(_x, mrows) do
                      mrows.select{|mrow| owners.any?(mrow[:role]) }
                    end,
                    sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
                  transform Merge::MultiRowLookup,
                    lookup: con_refs_for__registration_sets,
                    keycolumn: :registrationsetid,
                    fieldmap: {ownerorganizationlocal: :org},
                    conditions: ->(_x, mrows) do
                      mrows.select{|mrow| owners.any?(mrow[:role]) }
                    end,
                    sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
                end
              end

              acqsrc = config.con_role_treatment_mappings[:acquisitionsource]
              if Tms::ConRefs.for?('RegistrationSets')
                unless acqsrc.blank?
                  transform Merge::MultiRowLookup,
                    lookup: con_refs_for__registration_sets,
                    keycolumn: :registrationsetid,
                    fieldmap: {acquisitionsourcepersonlocal: :person},
                    conditions: ->(_x, mrows) do
                      mrows.select{|mrow| acqsrc.any?(mrow[:role]) }
                    end,
                    sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
                  transform Merge::MultiRowLookup,
                    lookup: con_refs_for__registration_sets,
                    keycolumn: :registrationsetid,
                    fieldmap: {acquisitionsourceorganizationlocal: :org},
                    conditions: ->(_x, mrows) do
                      mrows.select{|mrow| acqsrc.any?(mrow[:role]) }
                    end,
                    sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i)
                end
              end

              if config.multi_set_lots
                warn("Need to write multi_set_lots handling")
              else
                transform Rename::Field,
                  from: :lotnumber,
                  to: :acquisitionreferencenumber
              end

              transform Rename::Fields, fieldmap: {
                accessiondateiso: :accessiondategroup,
                approvaldateiso: :acquisitionauthorizerdate,
                accessionmethod: :acquisitionmethod
              }

              unless Tms::ObjAccession.dog_dates_treatment == :drop
                transform Prepend::ToFieldValue,
                  field: :deedofgiftsentiso,
                  value: 'Deed of gift sent: '
                transform Prepend::ToFieldValue,
                  field: :deedofgiftreceivediso,
                  value: 'Deed of gift received: '
              end

              unless Tms::ObjAccession.percentowned_treatment == :drop
                transform Prepend::ToFieldValue,
                  field: :percentowned,
                  value: Tms::ObjAccession.percentowned_prefix
              end

              unless config.note_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.note_sources,
                  target: :acquisitionnote,
                  sep: '%CR%',
                  delete_sources: true
              end
              unless config.proviso_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.proviso_sources,
                  target: :acquisitionprovisos,
                  sep: '%CR%',
                  delete_sources: true
              end
            end
          end
        end
      end
    end
  end
end
