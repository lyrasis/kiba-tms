# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module FlagOmitting
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__packages,
                destination: :packages__flag_omitting
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              # omit if packagetype=2
              transform do |row|
                row[:omit] = nil
                type = row[:packagetype]
                next row unless type == "2"

                row[:omit] = "packagetype = 2"
                row
              end

              # omit empty packages
              transform do |row|
                next row if row[:omit]

                count = row[:itemcount]
                next row unless count == "0"

                row[:omit] = "empty package"
                row
              end

              # omit packages for authorities
              transform do |row|
                next row if row[:omit]

                table = row[:tablename]
                next row unless config.omit_tables.any?(table)

                row[:omit] = "authority package (#{table})"
                row
              end

              # omit packages in RecycleBin
              transform do |row|
                next row if row[:omit]

                type = row[:foldertype]
                next row if type.blank?

                next row unless type.split(Tms.delim)
                  .any?("RecycleBin")

                row[:omit] = "in RecycleBin"
                row
              end

              # omit AlertQueue packages
              transform do |row|
                next row if row[:omit]

                type = row[:foldertype]
                next row if type.blank?

                next row unless type.split(Tms.delim)
                  .any?("AlertQueue")

                row[:omit] = "AlertQueue package"
                row
              end

              # omit AlertQueue packages
              transform do |row|
                next row if row[:omit]

                type = row[:foldertype]
                next row if type.blank?

                next row unless type.split(Tms.delim)
                  .any?("MoveAssistant")

                row[:omit] = "MoveAssistant package"
                row
              end
            end
          end
        end
      end
    end
  end
end
