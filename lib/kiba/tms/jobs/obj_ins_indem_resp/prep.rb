# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjInsIndemResp
        module Prep
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_ins_indem_resp,
                destination: :prep__obj_ins_indem_resp,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__indemnity_responsibilities if Tms::IndemnityResponsibilities.used?
            base << :prep__insurance_responsibilities if Tms::InsuranceResponsibilities.used?
            base
          end

          def xforms
            bind = binding
            
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              ins_ind_fields = config.ins_ind_fields
              
              transform Tms::Transforms::DeleteTmsFields

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              # remove rows with no values in remaining fields
              transform CombineValues::FromFieldsWithDelimiter,
                sources: ins_ind_fields,
                target: :combined,
                sep: Tms.delim,
                delete_sources: false
              transform Deduplicate::FieldValues, fields: :combined, sep: Tms.delim
              transform FilterRows::FieldEqualTo, action: :reject, field: :combined, value: '0'
              transform Delete::Fields, fields: :combined

              # merge in responsibility values
              if Tms::InsuranceResponsibilities.used?
                config.insurance_fields.each do |insresp|
                  transform Merge::MultiRowLookup,
                    keycolumn: insresp,
                    lookup: prep__insurance_responsibilities,
                    fieldmap: {
                      insresp=>:responsibility
                    },
                    delim: Tms.delim
                end
              end

              if Tms::IndemnityResponsibilities.used?
                config.indemnity_fields.each do |indemresp|
                  transform Merge::MultiRowLookup,
                    keycolumn: indemresp,
                    lookup: prep__indemnity_responsibilities,
                    fieldmap: {
                      indemresp=>:responsibility
                    },
                    delim: Tms.delim
                end
              end
              
              ins_ind_fields.each do |fieldname|
                labeltext = Tms::ObjInsIndemResp.fieldlabels[fieldname]
                transform Prepend::ToFieldValue, field: fieldname, value: "#{labeltext}: "
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: ins_ind_fields,
                target: :combined,
                sep: '%CR%%CR%',
                delete_sources: false
            end
          end
        end
      end
    end
  end
end
