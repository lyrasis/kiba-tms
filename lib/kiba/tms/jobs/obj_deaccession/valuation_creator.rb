# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDeaccession
        module ValuationCreator
          module_function

          # @param source [Symbol] field from which valuation control procedures
          #   will be created
          def job(source:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_deaccession,
                destination: "obj_deaccession__valuation_#{source}".to_sym
              },
              transformer: [
                config.valuation_note_creation_xforms[source],
                xforms(source)
              ].compact
            )
          end

          def xforms(field)
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              datefield = config.valuation_date_sources[field]
              valuetype = config.valuation_types[field]
              notesources = config.valuation_note_sources[field]
              valsrc = config.valuation_sources[field]

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: field
              transform Rename::Field,
                from: field,
                to: :valueamount

              if datefield
                transform Rename::Field,
                  from: datefield,
                  to: :valuedate
              end

              if valuetype
                transform Merge::ConstantValue,
                  target: :valuetype,
                  value: valuetype
              end

              transform Merge::ConstantValue,
                target: :valuecurrency,
                value: Tms.default_currency

              if notesources && !notesources.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: notesources,
                  target: :valuenote,
                  delim: Tms.notedelim
              end

              if valsrc
                renamemap = {
                  "org" => :valuesourceorganizationlocal,
                  "person" => :valuesourcepersonlocal
                }.transform_keys! { |key| "#{valsrc}_#{key}".to_sym }
                transform Rename::Fields, fieldmap: renamemap
              end

              transform Delete::FieldsExcept,
                fields: config.valuation_control_fields

              transform Copy::Field,
                from: :objectnumber,
                to: :idbase

              transform Merge::ConstantValue,
                target: :datasource,
                value: "ObjDeaccession.#{field}"
            end
          end
        end
      end
    end
  end
end
