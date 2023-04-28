# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module LocationNamesMerged
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_locations,
                destination: :obj_locations__location_names_merged,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups(mode = :main)
            base = %i[locs__compiled_clean]
            case mode
            when :main
              base << :prep__obj_locations
            else
              base << :tms__obj_locations
            end

            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms(mode = :main)
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              lookups = job.send(:lookups)

              lkup = mode == :main ? prep__obj_locations : tms__obj_locations
              idsrc = mode == :main ? :fulllocid : :locationid
              transform Merge::MultiRowLookup,
                lookup: lkup,
                keycolumn: :prevobjlocid,
                fieldmap: {
                  prevlocid: idsrc,
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: lkup,
                keycolumn: :nextobjlocid,
                fieldmap: {
                  nextlocid: idsrc,
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: lkup,
                keycolumn: :schedobjlocid,
                fieldmap: {
                  schedlocid: idsrc,
                },
                delim: Tms.delim

              if lookups.any?(:locs__compiled_clean)
                transform Merge::MultiRowLookup,
                  lookup: locs__compiled_clean,
                  keycolumn: :fulllocid,
                  fieldmap: {
                    location: :location_name,
                    locauth: :storage_location_authority
                  },
                  delim: Tms.delim
                transform Merge::MultiRowLookup,
                  lookup: locs__compiled_clean,
                  keycolumn: :prevlocid,
                  fieldmap: {
                    prev_location: :location_name,
                  },
                  delim: Tms.delim
                transform Merge::MultiRowLookup,
                  lookup: locs__compiled_clean,
                  keycolumn: :nextlocid,
                  fieldmap: {
                    next_location: :location_name,
                  },
                  delim: Tms.delim
                transform Merge::MultiRowLookup,
                  lookup: locs__compiled_clean,
                  keycolumn: :schedlocid,
                  fieldmap: {
                    sched_location: :location_name,
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields,
                fields: %i[locationid fulllocid prevlocid nextlocid schedlocid]
            end
          end
        end
      end
    end
  end
end
