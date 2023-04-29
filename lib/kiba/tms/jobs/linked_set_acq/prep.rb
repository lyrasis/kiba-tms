# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LinkedSetAcq
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :linked_set_acq__rows,
                destination: :linked_set_acq__prep,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            %i[
              prep__accession_lot
              prep__registration_sets
            ]
          end

          def multifield_hash
            fieldhash = Tms::ObjAccession.con_ref_target_fields
              .map { |field| [field, [field]] }
              .to_h
            Tms::AccessionLot.con_ref_target_fields.each do |field|
              if fieldhash.key?(field)
                fieldhash[field] << "lot_#{field}".to_sym
              else
                fieldhash[field] = ["lot_#{field}".to_sym]
              end
            end
            Tms::RegistrationSets.con_ref_target_fields.each do |field|
              if fieldhash.key?(field)
                fieldhash[field] << "set_#{field}".to_sym
              else
                fieldhash[field] = ["set_#{field}".to_sym]
              end
            end
            fieldhash
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              almap = Tms::Table::ContentFields.call(
                jobkey: :prep__accession_lot
              )
                .map { |field| ["lot_#{field}".to_sym, field] }
                .to_h
              transform Merge::MultiRowLookup,
                lookup: prep__accession_lot,
                keycolumn: :acquisitionlotid,
                fieldmap: almap
              transform Delete::Fields, fields: :acquisitionlotid

              rsmap = Tms::Table::ContentFields.call(
                jobkey: :prep__registration_sets
              )
                .map { |field| ["set_#{field}".to_sym, field] }
                .to_h
              transform Merge::MultiRowLookup,
                lookup: prep__registration_sets,
                keycolumn: :registrationsetid,
                fieldmap: rsmap

              bind.receiver.send(:multifield_hash).each do |target, fields|
                transform Tms::Transforms::CollapseMultisourceField,
                  fields: fields,
                  target: target
              end

              # The target should be the form used in ObjAccession, so we can
              #   reuse field handling methods from its config module
              {
                acquisitionauthorizerdate:
                  %i[set_approvaldateiso approvalisodate1],
                accessiondategroup: %i[set_accessiondateiso accessionisodate],
                deedofgiftsentiso: %i[set_deedofgiftsentiso deedofgiftsentiso],
                deedofgiftreceivediso:
                  %i[set_deedofgiftreceivediso deedofgiftreceivediso],
                currpercentownership: %i[set_percentowned currpercentownership],
                acquisitionmethod: %i[set_accessionmethod accessionmethod],
                creditline: %i[set_creditline creditline]
              }.each do |target, fields|
                transform Tms::Transforms::RankedSourceFields,
                  fields: fields,
                  target: target
              end

              if Tms::RegistrationSets.multi_set_lots
                warn("Need to write multi_set_lots handling")
              else
                transform Rename::Field,
                  from: :lot_lotnumber,
                  to: :acquisitionreferencenumber
              end

              unless Tms::ObjAccession.dog_dates_treatment == :drop
                transform Prepend::ToFieldValue,
                  field: :deedofgiftsentiso,
                  value: "Deed of gift sent: "
                transform Prepend::ToFieldValue,
                  field: :deedofgiftreceivediso,
                  value: "Deed of gift received: "
              end

              unless Tms::ObjAccession.percentowned_treatment == :drop
                transform Prepend::ToFieldValue,
                  field: :currpercentownership,
                  value: Tms::ObjAccession.percentowned_prefix
              end

              notesrcs = Tms::ObjAccession.note_sources
              unless notesrcs.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: notesrcs,
                  target: :acquisitionnote,
                  sep: "%CR%",
                  delete_sources: true
              end
              provsrcs = Tms::ObjAccession.proviso_sources
              unless provsrcs.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: provsrcs,
                  target: :acquisitionprovisos,
                  sep: "%CR%",
                  delete_sources: true
              end

              transform Rename::Fields, fieldmap: {
                set_objectstatus: :objectstatus
              }
            end
          end
        end
      end
    end
  end
end
