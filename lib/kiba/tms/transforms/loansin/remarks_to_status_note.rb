# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Loansin
        class RemarksToStatusNote
          def initialize
            @delim = Tms::Loansin.remarks_delim
            @target = :rem_loanstatusnote
            Tms::Loansin.status_sources << :rem
            Tms::Loansin.status_targets << :loanstatusnote
          end

          def process(row)
            row[target] = nil
            remarks = row[:remarks]
            row.delete(:remarks)
            return row if remarks.blank?

            vals = remarks.split(delim)
              .reject{ |remark| remark.empty? }
            row[target] = vals.join(Tms.delim)
            row
          end

          private

          attr_reader :delim, :target
        end
      end
    end
  end
end
