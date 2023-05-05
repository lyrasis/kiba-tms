# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module ClientDecisionWorksheet
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :packages__flag_migrating,
                destination: :packages__client_decision_worksheet,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.selection_done
              base << :packages__returned_compile
              base << :packages__previous_worksheet_compile
            end
            base.select { |jobkey| Tms.job_output?(jobkey) }
          end


          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if config.selection_done
                transform Merge::MultiRowLookup,
                  lookup: packages__previous_worksheet_compile,
                  keycolumn: :packageid,
                  fieldmap: {
                    inprev: :packageid
                  },
                  conditions: ->(_r, rows) { [rows.first] },
                  constantmap: {to_review: "n"}
              transform Delete::Fields, fields: :inprev
              end

              if config.selection_done
                transform Merge::MultiRowLookup,
                  lookup: packages__returned_compile,
                  keycolumn: :packageid,
                  fieldmap: {decision: :migrating},
                  constantmap: {to_review: "n"}

                transform do |row|
                  decision = row[:decision]
                  next row if decision.blank?

                  row[:migrating] = decision
                  row
                end
                transform Delete::Fields, fields: :decision
              transform do |row|
                next row unless row[:to_review].blank?

                omit = row[:omit]
                row[:to_review] = omit.blank? ? "y" : "n"
                row
              end
              transform Delete::FieldValueMatchingRegexp,
                fields: :to_review,
                match: "^n$"
              end

              transform Delete::Fields,
                fields: %i[packagetype tablename folderid folderdesc]
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
