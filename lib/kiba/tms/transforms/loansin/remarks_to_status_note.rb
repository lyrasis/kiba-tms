# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Loansin
        class RemarksToStatusNote
          def initialize
            @delim = Tms.delim
            @notedelim = Tms::Loansin.remarks_delim
          end

          def process(row)
            remarks = row[:remarks]
            return row if remarks.blank?

            notes = remarks.split(notedelim)
              .reject{ |remark| remark.empty? }
            row[:remarks] = notes.join(delim)
            row
          end

          private

          attr_reader :notedelim, :delim
        end
      end
    end
  end
end
