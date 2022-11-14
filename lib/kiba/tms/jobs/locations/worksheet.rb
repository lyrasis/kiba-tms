# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module Worksheet
          module_function

          def job
            if File.exist?(dest_path) && config.cleanup_done
              `cp #{dest_path} #{prev_version_path}`
            end

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :locs__compiled,
                destination: :locs__worksheet,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if prev_version_exist?
              base << :locations__worksheet_prev_version
            end
            if config.done
              base << :locations__worksheet_completed
            end
            base
          end

          def prev_version_exist?
            File.exist?(prev_version_path) && config.cleanup_done
          end

          def dest_path
            Tms.registry
              .resolve(:locs__worksheet)
              .path
          end

          def prev_version_path
            Tms.registry
              .resolve(:locs__worksheet_prev_version)
              .path
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Copy::Field, from: :location_name, to: :origlocname

              if bind.receiver.send(:prev_version_exist?)
                transform Merge::MultiRowLookup,
                  lookup: locations__worksheet_prev_version,
                  keycolumn: :fulllocid,
                  fieldmap: {
                    origlocname: :origlocname
                  }
              end

              if config.done
                transform Merge::MultiRowLookup,
                  lookup: locations__worksheet_completed,
                  keycolumn: :fulllocid,
                  fieldmap: {
                    correct_location_name: :correct_location_name,
                    correct_authority: :correct_authority,
                    correct_address: :correct_address,
                    doneid: :fulllocid
                  }

                transform do |row|
                  row[:to_review] = nil
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
