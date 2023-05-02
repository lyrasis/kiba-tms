# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module FlagMigrating
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :packages__flag_omitting,
                destination: :packages__flag_migrating
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              # n if omitted
              transform do |row|
                row[:migrating] = nil

                omit = row[:omit]
                next row unless omit

                row[:migrating] = "n"
                row
              end

              # y if public or conservationproject
              transform do |row|
                mig = row[:migrating]
                next row if mig

                type = row[:foldertype]
                next row if type.blank?

                types = type.split(Tms.delim)
                next row unless types.any?("Public") ||
                  types.any?("ConservationProject")

                row[:migrating] = "y"
                row
              end
            end
          end
        end
      end
    end
  end
end
