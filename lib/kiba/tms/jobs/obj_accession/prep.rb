# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_accession,
                destination: :prep__obj_accession,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
                      tms__objects
                      names__map_by_norm
                     ]
            if Tms::AccessionMethods.used? &&
                config.fields.any?(Tms::AccessionMethods.id_field)
              base << :prep__accession_methods
            end
            if Tms::Currencies.used? &&
                config.fields.any?(Tms::Currencies.id_field)
              base << :prep__currencies
            end
            if Tms::ConRefs.for?('ObjAccession')
              base << :con_refs_for__obj_accession
            end
            base
          end

          def xforms
            bind =  binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              accmeth = Tms::AccessionMethods
              curr = Tms::Currencies

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :objectid,
                value: '-1'

              transform Merge::MultiRowLookup,
                lookup: tms__objects,
                keycolumn: :objectid,
                fieldmap: {objectnumber: :objectnumber}

              transform Merge::MultiRowLookup,
                lookup: tms__objects,
                keycolumn: :objectid,
                fieldmap: {creditline: :creditline}

              if accmeth.used? && config.fields.any?(accmeth.id_field)
                transform Merge::MultiRowLookup,
                  lookup: prep__accession_methods,
                  keycolumn: accmeth.id_field,
                  fieldmap: {accmeth.type_field => accmeth.type_field}
              end
              transform Delete::Fields, fields: accmeth.id_field

              if curr.used? && config.fields.any?(curr.id_field)
                transform Merge::MultiRowLookup,
                  lookup: prep__currencies,
                  keycolumn: curr.id_field,
                  fieldmap: {curr.type_field => curr.type_field}
              end
              transform Delete::Fields, fields: curr.id_field

              if Tms::ConRefs.for?('ObjAccession')
                transform Tms::Transforms::ConRefs::Merger,
                  into: config,
                  keycolumn: :objectid
              end

              if config.fields.any?(:authorizer)
                transform Tms::Transforms::MergeUncontrolledName,
                  field: :authorizer,
                  lookup: names__map_by_norm
              end

              case config.authorizer_org_treatment
              when :drop
                transform Delete::Fields,
                  fields: :authorizer_org
              else
                transform Prepend::ToFieldValue,
                  field: :authorizer_org,
                  value: config.authorizer_org_prefix
              end

              case config.authorizer_note_treatment
              when :drop
                transform Delete::Fields,
                  fields: :authorizer_note
              else
                transform Prepend::ToFieldValue,
                  field: :authorizer_note,
                  value: config.authorizer_note_prefix
              end

              if config.fields.any?(:approvalisodate2)
                case config.approval_date_2_treatment
                when :drop
                  transform Delete::Fields,
                    fields: :approvalisodate2
                when :prefer
                  transform do |row|
                    d2 = row[:approvalisodate2]
                    next row if d2.blank?

                    row[:approvalisodate1] = d2
                    row
                  end
                else
                  transform Prepend::ToFieldValue,
                    field: :approvalisodate2,
                    value: config.approval_date_2_prefix
                end
              end

              if config.initiation_treatment == :drop
                transform Delete::Fields,
                  fields: %i[initiator initdate]
              else
                transform Tms::Transforms::ObjAccession::InitiationNote
              end

              unless config.proviso_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.proviso_sources,
                  target: :acquisitionprovisos,
                  sep: "\n",
                  delete_sources: true
              end
              unless config.note_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.note_sources,
                  target: :acquisitionnote,
                  sep: "\n",
                  delete_sources: true
              end
              unless config.reason_sources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.reason_sources,
                  target: :acquisitionreason,
                  sep: "\n",
                  delete_sources: true
              end

              transform Rename::Fields, fieldmap: {
                approvalisodate1: :acquisitionauthorizerdate,
                authorizer_person: :acquisitionauthorizer
              }
            end
          end
        end
      end
    end
  end
end
