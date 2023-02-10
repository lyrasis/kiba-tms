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
                      prep__exhibitions
                     ]
            base << :prep__obj_ins_indem_resp if Tms::ObjInsIndemResp.used
            base.select{ |job| Tms.job_output?(job) }
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

              if lookups.any?(:prep__exhibitions)
                transform Merge::MultiRowLookup,
                  lookup: prep__exhibitions,
                  keycolumn: :exhibitionid,
                  fieldmap: {
                    exhibitionnumber: :exhibitionnumber,
                    exhtitle: :exhtitle
                  }
              end
              if Tms::ObjTitles.used
                lookup = Tms.get_lookup(
                  jobkey: :prep__obj_titles,
                  column: :titleid
                )
                transform Merge::MultiRowLookup,
                  lookup: lookup,
                  keycolumn: :objtitleid,
                  fieldmap: {objecttitle: :title},
                  sorter: Lookup::RowSorter.new(on: :displayorder, as: :to_i),
                  conditions: ->(_row, rows) do
                    [rows.first]
                  end
              end

              if Tms::TextEntries.for?('ExhObjXrefs')
                transform Tms::TextEntries.for_exh_obj_xrefs_merge
              end
            end
          end
        end
      end
    end
  end
end
