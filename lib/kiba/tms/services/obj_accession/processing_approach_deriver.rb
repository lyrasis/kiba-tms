# frozen_string_literal: true

require "dry/monads"

module Kiba
  module Tms
    module Services
      module ObjAccession
        class ProcessingApproachDeriver
          include Dry::Monads[:result]

          def self.call(...)
            new(...).call
          end

          def initialize(counter: Tms::Services::RowCounter)
            @mod = Tms::ObjAccession
            @counter = counter
            @approaches = []
          end

          def call
            set_approaches.either(
              ->(success) { Success(approaches) },
              ->(failure) { Failure(failure) }
            )
          end

          private

          attr_reader :mod, :counter, :approaches

          def set_approaches
            approaches << :onetoone if mod.used? &&
              counter.call(:obj_accession__one_to_one) > 0
            approaches << :acqnumber if mod.used? &&
              counter.call(:obj_accession__acq_number) > 0
            approaches << :lotnumber if mod.used? &&
              counter.call(:obj_accession__lot_number) > 0
            approaches << :linkedlot if mod.used? &&
              counter.call(:obj_accession__linked_lot) > 0
            approaches << :linkedset if mod.used? &&
              counter.call(:obj_accession__linked_set) > 0
          rescue => err
            Failure(err)
          else
            Success()
          end
        end
      end
    end
  end
end
