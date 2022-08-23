# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Loansin
        class EvenStatusFields
          def initialize
            @delim = Tms.delim
            @notedelim = Tms::Loansin.remarks_delim
            @status = :rem_loanstatus
            @statusval = 'Note'
            @note = :rem_loanstatusnote
            Tms::Loansin.status_sources << :rem
            Tms::Loansin.status_targets << :loanstatusnote
          end

          def process(row)
            [status, note, :rem_loanindividual, :rem_loanstatusdate].each{ |field| row[field] = nil }
            remarks = row[:remarks]
            row.delete(:remarks)
            return row if remarks.blank?

            notes = remarks.split(notedelim)
              .reject{ |remark| remark.empty? }
            row[note] = notes.join(delim)
            statuses = notes.dup.map{ |note| statusval }
            row[status] = statuses.join(delim)
            row
          end

          private

          attr_reader :notedelim, :delim, :status, :statusval, :note
        end
      end
    end
  end
end
