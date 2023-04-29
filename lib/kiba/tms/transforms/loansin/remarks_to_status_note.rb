# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Loansin
        class RemarksToStatusNote
          def initialize
            @delim = Tms.delim
            @notedelim = Tms::Loansin.remarks_delim
            @targets = %i[rem_loanstatus rem_loanstatusdate rem_loanstatusnote
              rem_loanindividual]
          end

          def process(row)
            add_new_fields(row)
            remarks = row[:remarks]
            if remarks.blank?
              finalize(row)
            else
              process_remarks(row, remarks)
              finalize(row)
            end

            row
          end

          private

          attr_reader :notedelim, :delim, :targets

          def add_new_fields(row)
            targets.each { |field| row[field] = [] }
          end

          def finalize(row)
            targets.each do |field|
              arr = row[field]
              row[field] = arr.empty? ? nil : arr.join(delim)
            end
            row.delete(:remarks)
          end

          def process_remarks(row, remarks)
            split_remarks(remarks).each do |remark|
              %i[rem_loanstatusdate rem_loanindividual].each { |field|
                row[field] << "%NULLVALUE%"
              }
              row[:rem_loanstatus] << Tms::Loansin.remarks_status
              row[:rem_loanstatusnote] << remark
            end
          end

          def split_remarks(remarks)
            remarks.split(notedelim)
              .reject { |remark| remark.empty? }
          end
        end
      end
    end
  end
end
