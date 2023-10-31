# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module ReturnedPrep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__returned_compile,
                destination: :name_type_cleanup__returned_prep
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              default_type = Tms::Names.untyped_default

              # Add :authtypetent column with value if orig authoritytype was
              #   derived or questionable
              transform do |row|
                row[:authtypetent] = nil

                authtype = row[:authoritytype]
                next row if authtype.blank?
                next row unless authtype.end_with?(")", "?")

                row[:authtypetent] = "y"
                row
              end

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[correctname correctauthoritytype authtypetent]

              # Populate blank :correctauthoritytype with code for derived
              #   or questionable authoritytype value if :authtypetent
              transform do |row|
                cat = row[:correctauthoritytype]
                next row unless cat.blank?

                chk = row[:authtypetent]
                next row if chk.blank?

                at = row[:authoritytype]
                val = if at.blank?
                  (default_type == "Person") ? "p" : "o"
                elsif at.start_with?("P")
                  "p"
                else
                  "o"
                end
                row[:correctauthoritytype] = val

                row
              end

              transform do |row|
                origname = row[:origname]
                next row unless origname.blank?

                row[:origname] = row[:name]
                row
              end

              # drop rows that are Constituents with correctauthoritytype = d
              transform do |row|
                cat = row[:correctauthoritytype]
                next row unless cat == "d"

                src = row[:termsource]
                unless /^TMS Constituents\.(?:persons|orgs)$/.match?(src)
                  row
                end
              end

              transform Delete::FieldsExcept,
                fields: %i[correctname authoritytype correctauthoritytype
                  constituentid origname termsource cleanupid]

              transform Kiba::Extend::Transforms::Cspace::NormalizeForID,
                source: :origname,
                target: :orignorm
            end
          end
        end
      end
    end
  end
end
