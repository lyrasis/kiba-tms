# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForTermMasterThesTreatmentMergerHistoricnote
          include TermMasterThesMergeable
          include TreatmentMergeable
          include Tms::Transforms::ValueAppendable

          def initialize
            @target = :te_historicnote
            @delim = Tms.notedelim
          end

          private

          attr_reader :target, :delim
        end
      end
    end
  end
end
