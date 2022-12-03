# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module Worksheet
          module_function

          def job
            if File.exist?(config.worksheet_path) && config.done
              `cp #{config.worksheet_path} #{config.prev_worksheet_path}`
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
            if config.done
              base << :name_type_cleanup__returned_compile
              if config.prev_worksheet_exist?
                base << :name_type_cleanup__worksheet_prev_version
              end
            end
            base
          end

          def merge_map(fields)
            base = ( fields - nomerge_fields ).map{ |field| [field, field] }
              .to_h
            base.merge({doneid: :constituentid})
          end

          def nomerge_fields
            %i[name authoritytype constituentid cleanupid]
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Copy::Field, from: :name, to: :origname

              if config.prev_worksheet_exist?
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__worksheet_prev_version,
                  keycolumn: :constituentid,
                  fieldmap: {
                    origname: :origname
                  },
                  conditions: ->(_r, rows){ [rows.first] }
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituentid origname],
                target: :cleanupid,
                sep: '_',
                delete_sources: false

              transform Rename::Field, from: :contype, to: :authoritytype
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '%QUOT%',
                replace: '"'

              if config.done
                mergefields = bind.receiver
                  .send(:merge_map,
                        name_type_cleanup__returned_compile.first[1][0]
                          .keys)
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__returned_compile,
                  keycolumn: :cleanupid,
                  fieldmap: mergefields

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
