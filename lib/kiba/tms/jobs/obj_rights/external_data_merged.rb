# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjRights
        module ExternalDataMerged
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_rights,
                destination: :obj_rights__external_data_merged
              },
              transformer: [
                xforms,
                config.merge_end_xforms,
                consistent
              ].compact
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if Tms::TextEntries.for?("ObjRights") &&
                  Tms::TextEntriesForObjRights.merger_xforms
                Tms::TextEntriesForObjRights.merger_xforms.each do |xform|
                  transform xform
                end
              end

              if Tms::ConRefs.for?("ObjRights")
                if config.con_ref_name_merge_rules
                  transform Tms::Transforms::ConRefs::Merger,
                    into: config,
                    keycolumn: :objrightsid
                end
                Tms::ConRefsForObjRights.merger_xforms&.each { |xform|
                  transform xform
                }
              end
            end
          end

          def consistent
            Kiba.job_segment do
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
