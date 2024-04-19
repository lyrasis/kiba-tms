# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjDeaccession
        module Shape
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_deaccession,
                destination: :obj_deaccession__shape
              },
              transformer: get_xforms
            )
          end

          def get_xforms
            base = [config.pre_shape_xforms, default_initial_xforms,
              config.exitnumber_xforms]

            case config.treatment
            when :one_to_one
              base << one_to_one_xforms
            when :per_sale
              base << per_sale_xforms
            end

            base << default_end_xforms
            base << config.post_shape_xforms
            base.compact
          end

          def default_initial_xforms
            config = Tms::ObjDeaccession

            Kiba.job_segment do
              unless config.shape_delete_fields.empty?
                transform Delete::Fields,
                  fields: config.shape_delete_fields
              end

              transform Tms::Transforms::DeleteTimestamps,
                fields: :entereddate
              transform Merge::ConstantValue,
                target: :exitreason,
                value: "deaccession"
            end
          end

          def one_to_one_xforms
            config = Tms::ObjDeaccession

            Kiba.job_segment do
              if config.shape_content_fields.include?(:netsaleamount)
                transform Merge::ConstantValueConditional,
                  fieldmap: {disposalcurrency: Tms.default_currency},
                  condition: ->(row) do
                    amt = row[:netsaleamount]
                    !amt.blank? && !amt.start_with?("0")
                  end
              end
            end
          end

          def per_sale_xforms
            bind = binding

            Kiba.job_segment do
              job = bind.receiver
              config = job.config

              transform Deduplicate::Table,
                field: :salenumber

              transform Copy::Field,
                from: :salenumber,
                to: :salenumbernote
              transform Prepend::ToFieldValue,
                field: :salenumbernote,
                value: config.salenumber_note_prefix

              lkup = Tms.get_lookup(
                jobkey: :prep__obj_deaccession,
                column: :salenumber
              )

              # Aggregates lotnumber into a :lots note listing all lots in sale
              transform do |row|
                row[:lots] = nil
                salenum = row[:salenumber]
                next row if salenum.blank?

                lotranges = job.send(:derive_lot_ranges, salenum, lkup)
                next row unless lotranges

                row[:lots] = "#{config.lots_note_prefix}#{lotranges}"
                row
              end

              transform Append::NilFields,
                fields: %i[disposalcurrency displosalvalue
                  groupdisposalcurrency groupdisplosalvalue]

              # Sums netsaleamount and maps to :displosalvalue (if only one row
              # for sale) or :groupdisplosalvalue (if multiple rows for sale)
              transform do |row|
                salenum = row[:salenumber]
                next row if salenum.blank?

                amounts = lkup[salenum]

                if amounts.length == 1
                  amount = job.send(:derive_single_value, amounts)
                  prefix = ""
                else
                  amount = job.send(:derive_group_value, amounts)
                  prefix = "group"
                end
                next row unless amount

                curr_fld = "#{prefix}disposalcurrency".to_sym
                amt_fld = "#{prefix}displosalvalue".to_sym
                row[curr_fld] = Tms.default_currency
                row[amt_fld] = amount
                row
              end

              transform Delete::Fields,
                fields: :salenumber
            end
          end

          def default_end_xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              %i[
                estimatelow estimatehigh proceedsrcvdisodate reportisodate
              ].select { |fld| config.note_sources.include?(fld) }
                .each do |fld|
                  prefix_method = "#{fld}_note_prefix".to_sym
                  transform Prepend::ToFieldValue,
                    field: fld,
                    value: config.send(prefix_method)
                end

              sources = config.deaccessionapproval_source_fields
              targets = config.deaccessionapproval_target_fields
              if !sources.empty? && !targets.empty?
                config.date_fields.each do |datefld|
                  if sources.include?(datefld)
                    statusfld = "#{datefld}_deaccessionapprovalstatus".to_sym
                    targetfld = "#{datefld}_deaccessionapprovaldate".to_sym
                    statusmeth = "#{datefld}_status".to_sym
                    transform Merge::ConstantValueConditional,
                      fieldmap: {statusfld => config.send(statusmeth)},
                      condition: ->(row) { !row[datefld].blank? }
                    transform Rename::Field,
                      from: datefld,
                      to: targetfld
                  end
                end

                transform Collapse::FieldsToRepeatableFieldGroup,
                  sources: sources,
                  targets: targets,
                  delim: Tms.delim
              end

              config.note_fields.each do |fld|
                srcs = config.send("#{fld}_sources".to_sym)
                next if srcs.empty?

                transform CombineValues::FromFieldsWithDelimiter,
                  sources: srcs,
                  target: fld,
                  delim: Tms.notedelim
              end

              transform Rename::Fields, fieldmap: config.rename_map
              transform Delete::EmptyFields
            end
          end

          def derive_lot_ranges(salenum, lkup)
            lotnums = lot_numbers(salenum, lkup)
            return nil if lotnums.empty?

            lot_ranges(lotnums)
          end

          def lot_numbers(salenum, lkup)
            lkup[salenum].map { |row| row[:lotnumber] }
              .uniq
              .reject(&:blank?)
              .map(&:to_i)
              .sort
          end

          def lot_ranges(lotnums)
            prev = lotnums[0]
            lotnums.slice_before { |num|
              prev, prev2 = num, prev
              prev2 + 1 != num
            }.map { |arr| [arr[0], arr[-1]].uniq.map(&:to_s).join("-") }
              .join(", ")
          end

          def derive_single_value(rows)
            amount = rows.first[:netsaleamount]
            return nil if amount.blank?
            return nil if amount == "0.00"

            amount
          end

          def derive_group_value(rows)
            a = rows.map { |row| row[:netsaleamount] }
              .reject { |amt| amt.blank? }
              .map(&:to_f)
              .sum
              .to_s
              .split(".")
            [a[0], a[-1].ljust(2, "0")].join(".")
          end
        end
      end
    end
  end
end
