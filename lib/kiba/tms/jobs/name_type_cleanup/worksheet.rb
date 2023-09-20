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
            base.select { |jobkey| Tms.job_output?(jobkey) }
          end

          def returned_fields
            return [] unless config.done

            key = :name_type_cleanup__returned_compile
            path = Tms.registry.resolve(key).path
            Kiba::Extend::Command::Run.job(key) unless File.exist?(path)
            CSV.open(path, headers: true)
              .shift
              .headers
              .map(&:to_sym)
          end

          def mergeable_fields
            @mergeable_fields ||= returned_fields - nomerge_fields
          end

          def merge_map
            base = mergeable_fields.map { |field|
              ["m_#{field}".to_sym, field]
            }.to_h
            base.merge({doneid: :constituentid})
          end

          def nomerge_fields
            %i[name authoritytype constituentid cleanupid to_review]
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Copy::Field, from: :name, to: :origname

              if config.done
                transform Copy::Field,
                  from: :constituentid,
                  to: :nconid
                transform Tms::Transforms::Names::CleanExplodedId,
                  target: :nconid
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__previous_worksheet_compile,
                  keycolumn: :constituentid,
                  fieldmap: {
                    e_origname: :origname
                  },
                  conditions: ->(_r, rows) { [rows.first] }
                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__previous_worksheet_compile,
                  keycolumn: :nconid,
                  fieldmap: {
                    n_origname: :origname
                  },
                  conditions: ->(_r, rows) { [rows.first] }
                transform Append::NilFields,
                  fields: %i[to_review prevwrksheetmatchid]
                transform do |row|
                  origs = {
                    nconid: row[:n_origname],
                    constituentid: row[:e_origname]
                  }
                    .reject { |_k, val| val.blank? }
                  unless origs.empty?
                    case origs.length
                    when 1
                      row[:origname] = origs.values.first
                      idfield = origs.keys.first
                    else
                      row[:origname] = origs.values[1]
                      idfield = origs.keys[1]
                    end
                    row[:to_review] = "n"
                    row[:prevwrksheetmatchid] = idfield
                  end
                  row
                end
                transform Delete::Fields,
                  fields: %i[nconid e_origname n_origname]
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[constituentid origname],
                target: :cleanupid,
                delim: "_",
                delete_sources: false

              transform Rename::Field, from: :contype, to: :authoritytype

              if config.done
                mergefields = bind.receiver.send(:merge_map)

                transform Merge::MultiRowLookup,
                  lookup: name_type_cleanup__returned_compile,
                  keycolumn: :cleanupid,
                  fieldmap: mergefields

                transform do |row|
                  mergefields.each do |merged, base|
                    next if merged == :doneid

                    if row.key?(base)
                      mval = row[merged]
                      row[base] = mval unless mval.blank?
                    else
                      row[base] = row[merged]
                    end
                    row.delete(merged)
                  end
                  row
                end

                transform Tms::Transforms::Names::NormalizeContype,
                  source: :authoritytype,
                  target: :contype
                transform Tms::Transforms::Names::AddDefaultContype
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[contype name],
                  target: :corrfingerprint,
                  delim: " ",
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
                  if corrname && corrname["|"]
                    row[:correctname] = nil
                  end
                  if corrtype && corrtype["|"]
                    row[:correctauthoritytype] = nil
                  end
                  row
                end

                transform do |row|
                  next row unless row[:to_review].blank?

                  row[:to_review] = if !row[:alreadycorrected].blank? || !row[:doneid].blank?
                    "n"
                  else
                    "y"
                  end
                  row
                end

                transform do |row|
                  next row unless row[:to_review] == "y"

                  corrname = row[:corrnameval]
                  corrtype = row[:corrtypeval]
                  next row if corrname.blank? && corrtype.blank?

                  row[:correctname] = corrname unless corrname.blank?
                  row[:correctauthoritytype] = corrtype unless corrtype.blank?
                  row[:to_review] = "n"
                  row
                end
                transform Delete::FieldValueMatchingRegexp,
                  fields: :to_review,
                  match: "^n$"

                transform Delete::Fields,
                  fields: %i[alreadycorrected doneid corrnameval corrtypeval]
              else
                transform Append::NilFields,
                  fields: %i[correctauthoritytype correctname]
              end

              transform Clean::RegexpFindReplaceFieldVals,
                fields: :all,
                find: "%QUOT%",
                replace: '"'
            end
          end
        end
      end
    end
  end
end
