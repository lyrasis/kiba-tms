# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module Prep
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_components,
                destination: :prep__obj_components,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.actual_components
              base << %i[prep__obj_comp_types prep__obj_comp_statuses]
            end
            base << :text_entries__for_obj_components if config.merging_text_entries?
            base.flatten
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              
              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              
              transform FilterRows::FieldEqualTo, action: :reject, field: :componentid, value: '-1'
              
              if Tms::ObjComponents.actual_components
                transform Merge::MultiRowLookup,
                  lookup: prep__obj_comp_types,
                  keycolumn: :componenttype,
                  fieldmap: {
                    component_type: :objcomptype,
                  },
                  delim: Tms.delim
                transform Merge::MultiRowLookup,
                  lookup: prep__obj_comp_statuses,
                  keycolumn: :objcompstatusid,
                  fieldmap: {
                    objcompstatus: :objcompstatus,
                  },
                  delim: Tms.delim

              end
              transform Delete::Fields, fields: %i[componenttype objcompstatusid]

              if config.merging_text_entries?
                merger = config.text_entries_merge_xform.new(text_entries__for_obj_components)
                transform{ |row| merger.process(row) }
              end

              transform Replace::FieldValueWithStaticMapping,
                source: :inactive,
                target: :active,
                mapping: config.inactive_mapping
              transform Delete::Fields, fields: :inactive
            end
          end
        end
      end
    end
  end
end
