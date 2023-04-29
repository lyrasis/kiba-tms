# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ExhObjLoanObjXrefs
      extend Dry::Configurable
      module_function

      # ## About this table
      #
      # Each row links to a row in LoanObjXrefs and a row in ExhObjXrefs,
      #   with matching :objectnumber value in relation to Loan and Exhibition.
      #   No additional columns are defined in TMS.
      #
      # CS does not allow a three-way relationship between Object, specific
      #   Loan record, and Exhibition record.
      #
      # I tested whether using this table to create additional non-hierarchical
      #   relationships between Loans and Exhibitions added any new relations.
      #   In the case of mmm, it did not.
      extend Tms::Mixins::Tableable
    end
  end
end
