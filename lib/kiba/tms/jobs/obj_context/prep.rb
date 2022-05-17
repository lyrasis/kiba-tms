# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjContext
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_context,
                destination: :prep__obj_context,
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              
              transform FilterRows::FieldEqualTo, action: :reject, field: :objectid, value: '-1'
              
              consider_blank = {}
              %w[flag1 flag2 flag3 flag4 flag5 flag6 flag7 flag8 flag9 flag10 authority1id authority2id
                 authority3id authority4id authority5id authority6id authority7id authority8id authority9id
                 authority10id authority11id authority12id authority13id authority14id authority15id authority16id
                 authority17id authority18id authority19id authority20id authority21id authority22id authority23id
                 authority24id authority25id authority26id authority27id authority28id authority29id authority30id
                 authority31id authority32id authority33id authority34id authority35id authority36id authority37id
                 authority38id authority39id authority40id authority41id authority42id authority43id authority44id
                 authority45id authority46id authority47id authority48id authority49id authority50id authority51id
                 authority52id authority53id authority54id authority55id authority56id authority57id authority58id
                 authority59id authority60id authority61id authority62id authority63id authority64id authority65id
                 authority66id authority67id authority68id authority69id authority70id authority71id authority72id
                 authority73id authority74id authority75id authority76id authority77id authority78id authority79id
                 authority80id].each{ |field| consider_blank[field.to_sym] = '0' }
              transform Delete::EmptyFields, consider_blank: consider_blank

              client_specific_delete_fields = Tms.obj_context.delete_fields
              unless client_specific_delete_fields.empty?
                transform Delete::Fields, fields: client_specific_delete_fields
              end

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '^(%CR%)+',
                replace: ''
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '(%CR%)+$',
                replace: ''
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '(%CR%){3,}',
                replace: '%CR%%CR%'
            end
          end
        end
      end
    end
  end
end
