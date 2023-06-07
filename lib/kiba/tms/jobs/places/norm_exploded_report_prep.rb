# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module NormExplodedReportPrep
          module_function

          def job
            info = Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__norm_exploded,
                destination: :places__norm_exploded_report_prep,
                lookup: %i[
                           places__orig_normalized
                           obj_geography__mapping_review
                          ]
              },
              transformer: nil,
              mode: :setup
            )
            srcpath = info.files[:source][0].path
            destpath = info.files[:destination][0].path
            origlkup = info.context.places__orig_normalized
            exlkup = info.context.obj_geography__mapping_review
            build_report(srcpath, destpath, origlkup, exlkup)
          end

          def build_report(srcpath, destpath, orig, ex)
            examples = build_examples(srcpath, orig, ex)
            data = build_data(srcpath)
            write_report(examples, data, destpath)
            puts "Wrote report to #{destpath}"
          end

          def build_examples(srcpath, orig, ex)
            examples = {}
            CSV.foreach(
              srcpath, headers: true, header_converters: [:symbol]
            ) do |row|
              norm = row[:norm_combined]
              exdata = get_orig(norm, orig)
                .map{ |ofp| get_examples(ofp, ex) }
              next if exdata.empty?

              examples[norm] = exdata[0]
            end
            examples
          end

          def get_orig(norm, orig)
            rows = orig[norm]
            return [] if rows.blank?

            rows.map{ |row| row[:orig_combined] }
              .uniq
          end

          def get_examples(orig, ex)
            examples = ex[orig]
            return {} if examples.blank?

            data = {
              objnums: [],
              titles: [],
              descs: []
            }
            examples.first(10)
              .each do |row|
                data[:objnums] << row[:objectnumber]
                data[:titles] << row[:objecttitle]
                data[:descs] << row[:objectdesc]
              end
            data
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
              occs = row[:norm_combined_occs]&.to_i

              if data.key?(val)
                add_field_to_value(data, val, field, leftward, combined, occs)
              else
                data[val] = {
                  field=>{
                    leftward=>{
                      combined=>occs
                    }
                  }
                }
              end
            end
            data
          end

          def get_leftward(field, combined)
            if combined.match?(/^#{field}: [^|]+$/)
              "(single)"
            elsif combined.start_with?("#{field}: ")
              "(top)"
            else
              combined.sub(/\|\|\|#{field}: .*$/, "")
            end
          end

          def add_field_to_value(data, val, field, leftward, combined, occs)
            thisval = data[val]
            if thisval.key?(field)
              add_leftward_to_field(data, val, field, leftward, combined, occs)
            else
              thisval[field] = {
                leftward=>{
                  combined=>occs
                }
              }
            end
          end

          def add_leftward_to_field(data, val, field, leftward, combined, occs)
            thisfield = data[val][field]
            if thisfield.key?(leftward)
              add_combined_to_leftward(
                data, val, field, leftward, combined, occs
              )
            else
              thisfield[leftward] = {combined=>occs}
            end
          end

          def add_combined_to_leftward(
            data, val, field, leftward, combined, occs
          )
            thisleft = data[val][field][leftward]
            if thisleft.key?(combined)
              thisleft[combined] = thisleft[combined] += occs
            else
              thisleft[combined] = occs
            end
          end

          def write_report(examples, data, destpath)
            CSV.open(destpath, "w") do |csv|
              csv << %w[value fieldname key field_cat left_combined left_cat
                        norm_combined occs objectnumbers objecttitles
                        objectdescriptions]
              data.each do |value, fields|
                row = [value]
                add_fields(csv, row, fields, examples)
              end
            end
          end

          def add_fields(csv, row, fields, examples)
            fieldct = fields.keys.length
            cat = fieldct == 1 ? "single field" : "multi field"
            fields.each do |field, lefts|
              thisrow = row.dup
              thisrow << field
              thisrow << "#{row[0]}|||#{field}"
              thisrow << cat
              write_leftwards_details(csv, thisrow, lefts, examples)
            end
          end

          def write_leftwards_details(csv, row, lefts, examples)
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
              write_usage_details(csv, thisrow, usages, examples)
            end
          end

          def write_usage_details(csv, row, usages, examples)
            usages.each do |usage, occs|
              thisrow = row.dup
              thisrow << usage
              thisrow << occs
              write_examples(csv, thisrow, usage, examples)
            end
          end

          def write_examples(csv, row, usage, examples)
            examples_for_row(usage, examples).each{ |val| row << val }
            csv << row
          end

          def examples_for_row(usage, examples)
            exdata = examples[usage]
            return ["", "", ""] if exdata.blank?

            exdata.values
              .map{ |vals| vals.join(Tms.delim) }
          end

          # def get_rightward(row, usage)
          #   parts = usage.split('|||')
          #   return "" if parts.length == 1

          #   leftcat = row[-2]
          #   return get_after_first(parts) if leftcat == "(starts with)"

          #   get_after_subsequent(parts, row, usage)
          # end

          # def get_after_first(parts)
          #   parts.shift
          #   parts.join("|||")
          # end

          # def get_after_subsequent(parts, row, usage)
          #   field = row[1]
          #   field_idx = parts.find_index{ |part| part.start_with?("#{field}: ") }
          #   (field_idx + 1).times{ parts.shift }
          #   parts.join("|||")
          # end
        end
      end
    end
  end
end
