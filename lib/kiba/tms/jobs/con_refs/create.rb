# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConRefs
        module Create
          module_function

          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__con_xref_details,
                destination: :con_refs__create,
                lookup: :prep__con_xrefs
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              merge_fields = Tms::ConXrefs.fields - [:conxrefid]
              merge_map = merge_fields.map{ |field| [field, field] }.to_h
              transform Merge::MultiRowLookup,
                lookup: prep__con_xrefs,
                keycolumn: :conxrefid,
                fieldmap: merge_map,
                delim: Tms.delim
              transform Delete::Fields, fields: :conxrefid
            end
          end
        end
      end
    end
  end
end
