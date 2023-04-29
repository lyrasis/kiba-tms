# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Exhibitions
        module MergeExhObjInfo
          module_function

          def job
            return unless config.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :exhibitions__shaped,
                destination: :exhibitions__merge_exh_obj_info
              },
              transformer: xforms
            )
          end

          def xref_lookup
            Tms.get_lookup(
              jobkey: :prep__exh_obj_xrefs,
              column: :exhibitionid
            )
          end

          def xforms
            send(get_xforms)
          end

          def get_xforms
            if !config.migrate_exh_obj_info &&
                Tms::ExhObjXrefs.text_entry_handling == :drop
              :passthrough
            elsif config.migrate_exh_obj_info &&
                Tms::ExhObjXrefs.text_entry_handling == :drop
              :obj_info
            elsif !config.migrate_exh_obj_info &&
                Tms::ExhObjXrefs.text_entry_handling ==
                    :exhibition_planning_note
              :text_entry_notes
            elsif !config.migrate_exh_obj_info &&
                Tms::ExhObjXrefs.text_entry_handling ==
                    :exhibited_object_information
              :obj_info_text_entries
            else
              :unhandled
            end
          end

          def passthrough
            Kiba.job_segment do
            end
          end

          def obj_info
            Kiba.job_segment do
              warn(
                "#{job.send(:name)}: Implement merge of object details"
              )
            end
          end

          def text_entry_notes
            bind = binding

            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: bind.receiver.send(:xref_lookup),
                keycolumn: :exhibitionid,
                fieldmap: {te_planningnote: :planningnote},
                delim: "%CR%",
                conditions: ->(_tr, rows) {
                  rows.reject { |r| r[:text_entry].blank? }
                }
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[planningnote te_planningnote],
                target: :planningnote,
                sep: "%CR%",
                delete_sources: true
            end
          end

          def obj_info_text_entries
            bind = binding

            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: bind.receiver.send(:xref_lookup),
                keycolumn: :exhibitionid,
                fieldmap: {
                  exhibitionobjectnumber: :objectnumber,
                  exhibitionobjectname: :objecttitle,
                  exhibitionobjectnote: :text_entry
                },
                delim: Tms.delim,
                conditions: ->(_tr, rows) {
                  rows.reject { |r| r[:text_entry].blank? }
                }
            end
          end

          def unhandled
            Kiba.job_segment do
              warn(
                "#{job.send(:name)}: Unhandled ExhObjInfo/TextEntries combo"
              )
            end
          end
        end
      end
    end
  end
end
