# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module CleanedExplodedReportPrep
          module_function

          def job
            info = Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__cleaned_exploded,
                destination: :places__cleaned_exploded_report_prep,
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
            # max number of examples to return for a given :norm_combineds value
            max = 10
            build_report(srcpath, destpath, origlkup, exlkup, max)
          end

          def build_report(srcpath, destpath, orig, ex, max)
            examples = build_example_data(srcpath, orig, ex, max)
            data = build_data(srcpath)
            write_report(examples, data, destpath)
            puts "Wrote report to #{destpath}"
          end

          def build_example_data(srcpath, orig, ex, max)
            examples = {}
            CSV.foreach(
              srcpath, headers: true, header_converters: [:symbol]
            ) do |row|
              allnorms = row[:norm_combineds]
              next if allnorms.blank?

              norms = allnorms.split(Tms::Places.norm_fingerprint_delim)

              exdata = norms.map do |norm|
                get_norm_examples(norm, orig, ex, max / norms.size)
              end

              next if exdata.blank?
              exdata.flatten!
              excontent = exdata.reject{ |ex| ex.blank? }
              examples[allnorms] = merge_examples(excontent)
            end
            examples
          end

          def merge_examples(excontent)
            return {} if excontent.blank?

            base = {}
            %i[objnums titles descs].each do |field|
              base[field] = excontent.map{ |ex| ex[field] }
                .flatten
                .compact
            end
            base
          end

          def get_norm_examples(norm, orig, ex, max)
            get_orig(norm, orig)
              .map{ |ofp| get_examples(ofp, ex, max) }
          end

          def get_orig(norm, orig)
            rows = orig[norm]
            return [] if rows.blank?

            rows.map{ |row| row[:orig_combined] }
              .uniq
          end

          def get_examples(orig, ex, max)
            examples = ex[orig]
            return {} if examples.blank?

            data = {
              objnums: [],
              titles: [],
              descs: []
            }
            examples.first(max)
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
              combined = row[:clean_combined]
              norms = row[:norm_combineds]
              leftward = get_leftward(field, combined)
              occs = row[:occurrences]&.to_i

              if data.key?(val)
                add_field_to_value(data, val, field, leftward, combined, norms,
                                   occs)
              else
                data[val] = {
                  field=>{
                    leftward=>{
                      combined=>{occs: occs, norms: norms}
                    }
                  }
                }
              end
            end
            data
          end

          def get_leftward(field, combined)
            c_segs = combined.split("|||")
              .map{ |pairstr| split_field_val_pair(pairstr) }
              .to_h

            return "(single)" if c_segs.length == 1

            leftward = compile_leftward(field, c_segs)

            binding.pry if field == "city" &&
              c_segs.length == 2 &&
              c_segs['city'] == "Bodega Bay"

            return "(top)" if leftward.empty?

            leftward.map{ |key, val| "#{key}: #{val}" }
              .join("|||")
          end

          def compile_leftward(field, c_segs)
            hierarchy_leftward(field, c_segs).merge(
              non_hierarchy_leftward(field, c_segs)
            )
          end

          def hierarchy_leftward(field, c_segs)
            left_segs = {}
            Tms::Places.hierarchy_fields
              .reverse
              .map(&:to_s)
              .each do |hierfield|
                break if hierfield == field

                val = c_segs[hierfield]
                next if val.blank?

                left_segs[hierfield] = val
              end
            left_segs
          end

          def non_hierarchy_leftward(field, c_segs)
            return [] if Tms::Places.hierarchy_fields.any?(field)

            fields = Tms::Places.non_hierarchy_fields
            segs = {}
            fields.each do |srcfield|
              break if srcfield == field

              val = c_segs[srcfield]
              next if val.blank?

              segs[srcfield] = val
            end
            segs
          end

          def split_field_val_pair(pair)
            init = pair.split(": ")
            return init if init.length == 2

            [init[0], init[1..-1].join(": ")]
          end

          def add_field_to_value(data, val, field, leftward, combined, norms,
                                 occs)
            thisval = data[val]
            if thisval.key?(field)
              add_leftward_to_field(data, val, field, leftward, combined, norms,
                                    occs)
            else
              thisval[field] = {
                leftward=>{
                  combined=>{occs: occs, norms: norms}
                }
              }
            end
          end

          def add_leftward_to_field(data, val, field, leftward, combined, norms,
                                    occs)
            thisfield = data[val][field]
            if thisfield.key?(leftward)
              add_combined_to_leftward(
                data, val, field, leftward, combined, norms, occs
              )
            else
              thisfield[leftward] = {combined=>{occs: occs, norms: norms}}
            end
          end

          def add_combined_to_leftward(
            data, val, field, leftward, combined, norms, occs
          )
            thisleft = data[val][field][leftward]
            if thisleft.key?(combined)
              newoccs = thisleft[combined][:occs] += occs
              newnorms = [
                thisleft[combined][:norms],
                norms
              ].join(Tms::Places.norm_fingerprint_delim)
              thisleft[combined] = {occs: newoccs, norms: newnorms}
            else
              thisleft[combined] = {occs: occs, norms: norms}
            end
          end

          def write_report(examples, data, destpath)
            CSV.open(destpath, "w") do |csv|
              csv << %w[value fieldname key field_cat left_combined left_cat
                        clean_combined occs objectnumbers objecttitles
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
                        "single broader"
                      else
                        "multi broader"
                      end
            lefts.each do |left, usages|
              thisrow = row.dup
              thisrow << left
              thisrow << leftcat
              write_usage_details(csv, thisrow, usages, examples)
            end
          end

          def write_usage_details(csv, row, usages, examples)
            usages.each do |usage, details|
              thisrow = row.dup
              thisrow << usage
              thisrow << details[:occs]
              write_examples(csv, thisrow, details[:norms], examples)
            end
          end

          def write_examples(csv, row, norms, examples)
            examples_for_norms(norms, examples)
              .each{ |val| row << val }
            csv << row
          end

          def examples_for_norms(norms, examples)
            exdata = examples[norms]
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
