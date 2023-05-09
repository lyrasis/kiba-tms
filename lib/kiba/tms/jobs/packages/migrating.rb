# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module Migrating
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :packages__flag_migrating,
                destination: :packages__migrating,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if config.selection_done
              base << :packages__returned_compile
            end
            base.select { |job| Tms.job_output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldPopulated,
                action: :reject,
                field: :omit

              if config.selection_done
                transform Merge::MultiRowLookup,
                  lookup: packages__returned_compile,
                  keycolumn: :packageid,
                  fieldmap: {decision: :migrating}
                transform do |row|
                  decision = row[:decision]
                  row[:migrating] = decision.blank? ? "n" : decision
                  row.delete(:decision)
                  row
                end
              end
              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :migrating,
                value: "y"

              transform Delete::Fields,
                fields: %i[omit migrating packagetype modifieddate
                  modifiedloginid lastuseddate lastusedloginid
                  itemcount tablename folderid foldername
                  folderdesc foldertype]
            end
          end
        end
      end
    end
  end
end
