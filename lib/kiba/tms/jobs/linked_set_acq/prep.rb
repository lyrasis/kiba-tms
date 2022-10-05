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
            base = %i[
                      prep__accession_lot
                      prep__registration_sets
                     ]
            base
          end

          def xforms
            Kiba.job_segment do
              fmap = Tms::AccessionLot.content_fields.map do |field|
                [field, "lot_#{field}".to_sym]
              end.to_h
              transform Merge::MultiRowLookup,
                lookup: prep__accession_lot,
                keycolumn: :acquisitionlotid,
                fieldmap: fmap
              transform Delete::Fields, fields: :acquisitionlotid

              # if config.multi_set_lots
              #   warn("Need to write multi_set_lots handling")
              # else
              #   transform Rename::Field,
              #     from: :lotnumber,
              #     to: :acquisitionreferencenumber
              # end

              # transform Rename::Fields, fieldmap: {
              #   accessiondateiso: :accessiondategroup,
              #   approvaldateiso: :acquisitionauthorizerdate,
              #   accessionmethod: :acquisitionmethod
              # }

              # unless Tms::ObjAccession.dog_dates_treatment == :drop
              #   transform Prepend::ToFieldValue,
              #     field: :deedofgiftsentiso,
              #     value: 'Deed of gift sent: '
              #   transform Prepend::ToFieldValue,
              #     field: :deedofgiftreceivediso,
              #     value: 'Deed of gift received: '
              # end

              # unless Tms::ObjAccession.percentowned_treatment == :drop
              #   transform Prepend::ToFieldValue,
              #     field: :percentowned,
              #     value: Tms::ObjAccession.percentowned_prefix
              # end

              # unless config.note_sources.empty?
              #   transform CombineValues::FromFieldsWithDelimiter,
              #     sources: config.note_sources,
              #     target: :acquisitionnote,
              #     sep: '%CR%',
              #     delete_sources: true
              # end
              # unless config.proviso_sources.empty?
              #   transform CombineValues::FromFieldsWithDelimiter,
              #     sources: config.proviso_sources,
              #     target: :acquisitionprovisos,
              #     sep: '%CR%',
              #     delete_sources: true
              # end

            end
          end
        end
      end
    end
  end
end
