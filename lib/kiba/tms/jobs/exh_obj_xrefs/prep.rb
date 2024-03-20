# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ExhObjXrefs
        module Prep
          module_function

          def job
            return unless config.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__exh_obj_xrefs,
                destination: :prep__exh_obj_xrefs,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
              objects__number_lookup
              exhibitions__shaped
            ]
            base << :prep__obj_ins_indem_resp if Tms::ObjInsIndemResp.used
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Tms::Transforms::DeleteTmsFields

              if config.omitting_fields?
                transform Delete::Fields,
                  fields: config.omitted_fields
              end
              transform Tms.data_cleaner if Tms.data_cleaner

              if lookups.any?(:objects__number_lookup)
                transform Merge::MultiRowLookup,
                  lookup: objects__number_lookup,
                  keycolumn: :objectid,
                  fieldmap: {objectnumber: :objectnumber}
              end

              if lookups.any?(:exhibitions__shaped)
                transform Merge::MultiRowLookup,
                  lookup: exhibitions__shaped,
                  keycolumn: :exhibitionid,
                  fieldmap: {
                    exhibitionnumber: :exhibitionnumber,
                    exhtitle: :exhtitle
                  }
              end

              if Tms::TextEntries.for?("ExhObjXrefs") &&
                  Tms::TextEntriesForExhObjXrefs.merger_xforms
                Tms::TextEntriesForExhObjXrefs.merger_xforms.each do |xform|
                  transform xform
                end

                if config.text_entry_handling == :exhibition_planning_note
                  transform CombineValues::FromFieldsWithDelimiter,
                    sources: %i[objectnumber text_entry],
                    target: :planningnote,
                    delim: ": ",
                    delete_sources: false
                end
              end
            end
          end
        end
      end
    end
  end
end
