# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module AuthNormExplodedReport
          module_function

          def job
            return unless config.used?

            info = Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_geography__auth_norm_exploded,
                destination: :obj_geography__auth_norm_exploded_report
              },
              transformer: nil,
              mode: :setup
            )
            info.handle_requirements
            srcpath = info.files[:source][0].path
            destpath = info.files[:destination][0].path
            build_report(srcpath, destpath)
          end

          def build_report(srcpath, destpath)
            data = build_data(srcpath)
            write_report(data, destpath)
          end

          def build_data(srcpath)
            data = {}
            CSV.foreach(
              srcpath, headers: true, header_converters: [:symbol]
            ) do |row|
              val = row[:value]
              field = row[:fieldname]
              combined = row[:norm_combined]
              leftward = get_leftward(field, combined)

              if data.key?(val)
                add_field_to_value(data, val, field, leftward, combined)
              else
                data[val] = {
                  field=>{
                    leftward=>{
                      combined=>1
                    }
                  }
                }
              end
            end
            data
          end

          def get_leftward(field, combined)
            if combined.start_with?("#{field}: ")
              "(starts with)"
            else
              combined.sub(/\|\|\|#{field}: .*$/, "")
            end
          end

          def add_field_to_value(data, val, field, leftward, combined)
            thisval = data[val]
            if thisval.key?(field)
              add_leftward_to_field(data, val, field, leftward, combined)
            else
              thisval[field] = {
                leftward=>{
                  combined=>1
                }
              }
            end
          end

          def add_leftward_to_field(data, val, field, leftward, combined)
            thisfield = data[val][field]
            if thisfield.key?(leftward)
              add_combined_to_leftward(data, val, field, leftward, combined)
            else
              thisfield[leftward] = {combined=>1}
            end
          end

          def add_combined_to_leftward(data, val, field, leftward, combined)
            thisleft = data[val][field][leftward]
            if thisleft.key?(combined)
              thisleft[combined] = thisleft[combined] += 1
            else
              thisleft[combined] = 1
            end
          end

          def write_report(data, destpath)
            CSV.open(destpath, "w") do |csv|
              csv << %w[value fieldname key field_cat left_combined left_cat
                        right_combined right_cat norm_combined]
              data.each do |value, fields|
                row = [value]
                add_fields(csv, row, fields)
              end
            end
          end

          def add_fields(csv, row, fields)
            fieldct = fields.keys.length
            cat = fieldct == 1 ? "single field" : "multi field"
            fields.each do |field, lefts|
              thisrow = row.dup
              thisrow << field
              thisrow << "#{row[0]}|||#{field}"
              thisrow << cat
              write_leftwards_details(csv, thisrow, lefts)
            end
          end

          def write_leftwards_details(csv, row, lefts)
            leftct = lefts.keys.length
            leftcat = if leftct == 1
                        "single broader usage pattern in field"
                      else
                        "multiple broader usage patterns in field"
                      end
            lefts.each do |left, usages|
              thisrow = row.dup
              thisrow << left
              thisrow << leftcat
              write_usage_details(csv, thisrow, usages)
            end
          end

          def write_usage_details(csv, row, usages)
            usagect = usages.keys.length
            usecat = if usagect == 1
                       "single narrower usage pattern"
                     else
                       "multi narrower usage patterns"
                     end
            usages.each do |usage, occs|
              thisrow = row.dup
              thisrow << get_rightward(thisrow, usage)
              thisrow << usecat
              thisrow << usage
              csv << thisrow
            end
          end

          def get_rightward(row, usage)
            parts = usage.split('|||')
            return "" if parts.length == 1

            leftcat = row[-2]
            return get_after_first(parts) if leftcat == "(starts with)"

            get_after_subsequent(parts, row, usage)
          end

          def get_after_first(parts)
            parts.shift
            parts.join("|||")
          end

          def get_after_subsequent(parts, row, usage)
            field = row[1]
            field_idx = parts.find_index{ |part| part.start_with?("#{field}: ") }
            (field_idx + 1).times{ parts.shift }
            parts.join("|||")
          end
        end
      end
    end
  end
end
