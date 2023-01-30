# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module Worksheet
          module_function

          def job
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
              base << :name_type_cleanup__previous_worksheet_compile
              base << :name_type_cleanup__corrected_name_lookup
              base << :name_type_cleanup__corrected_value_lookup
            end
            base.select{ |jobkey| Tms.job_output?(jobkey) }
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

              if config.done
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__previous_worksheet_compile,
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

              if config.done
                mergefields = bind.receiver
                  .send(:merge_map,
                        name_type_cleanup__returned_compile.first[1][0]
                          .keys)
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__returned_compile,
                  keycolumn: :cleanupid,
                  fieldmap: mergefields

                transform Tms::Transforms::Names::NormalizeContype,
                  source: :authoritytype,
                  target: :contype
                transform Tms::Transforms::Names::AddDefaultContype
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[contype name],
                  target: :corrfingerprint,
                  sep: ' ',
                  delete_sources: false
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__corrected_name_lookup,
                  keycolumn: :corrfingerprint,
                  fieldmap: {alreadycorrected: :corrfingerprint}
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__corrected_value_lookup,
                  keycolumn: :corrfingerprint,
                  fieldmap: {
                    corrnameval: :correctname
                  },
                  delim: Tms.delim
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__corrected_value_lookup,
                  keycolumn: :corrfingerprint,
                  fieldmap: {
                    corrtypeval: :correctcontype
                  },
                  delim: Tms.delim

                transform do |row|
                  corrname = row[:correctname]
                  corrtype = row[:correctauthoritytype]
                  if corrname && corrname['|']
                    row[:correctname] = nil
                  end
                  if corrtype && corrtype['|']
                    row[:correctauthoritytype] = nil
                  end
                  row
                end

                transform do |row|
                  row[:to_review] = nil
                  next row unless row[:alreadycorrected].blank?
                  next row unless row[:doneid].blank?

                  row[:to_review] = 'y'
                  row
                end

                transform do |row|
                  next row unless row[:to_review] == 'y'

                  corrname = row[:corrnameval]
                  corrtype = row[:corrtypeval]
                  next row if corrname.blank? && corrtype.blank?

                  row[:correctname] = corrname unless corrname.blank?
                  row[:correctauthoritytype] = corrtype unless corrtype.blank?
                  row[:to_review] = nil
                  row
                end

                transform Delete::Fields,
                  fields: %i[alreadycorrected doneid corrnameval corrtypeval]
              else
                transform Append::NilFields,
                  fields: %i[correctauthoritytype correctname]
              end

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: '%QUOT%',
                replace: '"'
            end
          end
        end
      end
    end
  end
end
