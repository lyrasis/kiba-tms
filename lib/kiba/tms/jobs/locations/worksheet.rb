# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Worksheet
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__compiled_clean,
                destination: :locs__worksheet,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.cleanup_done
              base << :locs__previous_worksheet_compile
              base << :locs__returned_compile
            end
            base.select{ |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.send(:config)
              lookups = job.send(:lookups)

              transform Copy::Field, from: :location_name, to: :origlocname

              if lookups.any?(:locs__previous_worksheet_compile)
                transform Merge::MultiRowLookup,
                  lookup: locs__previous_worksheet_compile,
                  keycolumn: :fulllocid,
                  fieldmap: {
                    origlocname: :origlocname
                  },
                  constantmap: {to_review: 'n'}
              end

              if config.cleanup_done
                transform Merge::MultiRowLookup,
                  lookup: locs__returned_compile,
                  keycolumn: :fulllocid,
                  fieldmap: {
                    correct_location_name: :correct_location_name,
                    correct_authority: :correct_authority,
                    correct_address: :correct_address,
                    doneid: :fulllocid
                  }

                transform do |row|
                  done = row[:doneid]
                  next row unless done.blank?

                  row[:to_review] = 'y'
                  row
                end
                transform Delete::Fields, fields: :doneid
              else
                transform Append::NilFields,
                  fields: %i[correct_location_name correct_authority
                             correct_address]
              end
            end
          end
        end
      end
    end
  end
end
