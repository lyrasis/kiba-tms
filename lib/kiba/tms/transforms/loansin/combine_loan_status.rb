# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Loansin
        class CombineLoanStatus
          def initialize
            @delim = Tms.delim
            @source = :tmsloanstatus
            @target = :loanstatus
            @nulltargets = %i[loanstatusdate loanstatusnote loanindividual]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: nulltargets + [target]
            )
          end

          def process(row)
            status = row[source]
            if status.blank?
              finalize(row)
            else
              combined = combine_status(row, status)
              row.merge!(combined)
              finalize(row)
            end
            
            row
          end

          private

          attr_reader :delim, :source, :target, :nulltargets, :getter

          def add_status(vals, status)
            vals.transform_values!{ |val| val.split(delim) }
            vals[target] << status
            nulltargets.each{ |field| vals[field] << "%NULLVALUE%" if vals.key?(field) }
            vals.transform_values{ |val| val.join(delim) }
          end
          
          def process_status(vals, status)
            chk = vals.transform_values{ |val| val.downcase.split(delim) }
            chk[target].any?(status.downcase) ? vals : add_status(vals, status)
          end
          
          def combine_status(row, status)
            vals = getter.call(row)
            vals.empty? ? new_status(status) : process_status(vals, status)
          end
          
          def finalize(row)
            row.delete(source)
          end

          def new_status(status)
            h = {target: status}
            nulltargets.each{ |field| h[field] = Tms.nullvalue }
            h
          end
          
          def process_remarks(row, remarks)
            split_remarks(remarks).each do |remark|
              %i[rem_loanstatusdate rem_loanindividual].each{ |field| row[field] << "%NULLVALUE%" }
              row[:rem_loanstatus] << Tms::Loansin.remarks_status
              row[:rem_loanstatusnote] << remark
            end
          end
          
          def split_remarks(remarks)
            remarks.split(notedelim)
              .reject{ |remark| remark.empty? }
          end
        end
      end
    end
  end
end
