# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module Worksheet
          module_function

          def job
            if File.exist?(dest_path) && config.done
              `cp #{dest_path} #{prev_version_path}`
            end

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__from_base_data,
                destination: :name_type_cleanup__worksheet,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if prev_version_exist?
              base << :name_type_cleanup__worksheet_prev_version
            end
            if config.done
              base << :name_type_cleanup__worksheet_completed
            end
            base
          end

          def prev_version_exist?
            File.exist?(prev_version_path) && config.done
          end

          def dest_path
            Tms.registry
              .resolve(:name_type_cleanup__worksheet)
              .path
          end

          def prev_version_path
            Tms.registry
              .resolve(:name_type_cleanup__worksheet_prev_version)
              .path
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              pre_process do
              end

              config = bind.receiver.send(:config)

              transform Copy::Field, from: :name, to: :origname

              if bind.receiver.send(:prev_version_exist?)
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__worksheet_prev_version,
                  keycolumn: :constituentid,
                  fieldmap: {
                    origname: :origname
                  }
              end

              transform Rename::Field, from: :contype, to: :authoritytype
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '%QUOT%',
                replace: '"'

              if config.done
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__worksheet_completed,
                  keycolumn: :constituentid,
                  fieldmap: {
                    correctauthoritytype: :correctauthoritytype,
                    correctname: :correctname,
                    doneid: :constituentid
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
                  fields: %i[correctauthoritytype correctname]
              end

            end
          end
        end
      end
    end
  end
end
