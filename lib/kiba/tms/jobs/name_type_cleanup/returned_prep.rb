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
                source: :name_type_cleanup__worksheet_completed,
                destination: :name_type_cleanup__returned_prep
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              # add column with value if orig authoritytype was derived or
              #   questionable
              transform do |row|
                row[:authtypetent] = nil

                authtype = row[:authoritytype]
                next row if authtype.blank?
                next row unless authtype.end_with?(')') ||
                  authtype.end_with?('?')

                row[:authtypetent] = 'y'
                row
              end

              transform FilterRows::AnyFieldsPopulated,
                action: :keep,
                fields: %i[correctname correctauthoritytype authtypetent]

              # populate blank correctauthoritytype with code for derived
              #   or questionable authoritytype value
              transform do |row|
                cat = row[:correctauthoritytype]
                next row unless cat.blank?

                chk = row[:authtypetent]
                next row if chk.blank?

                at = row[:authoritytype]
                if at.blank?
                  val = config.untyped_treatment == 'Person' ? 'p' : 'o'
                elsif at.start_with?('P')
                  val = 'p'
                else
                  val = 'o'
                end
                row[:correctauthoritytype] = val

                row
              end
              transform Delete::FieldsExcept,
                fields: %i[correctname correctauthoritytype termsource
                           constituentid]
            end
          end
        end
      end
    end
  end
end