# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Services
      class UniqueTypeValuesUsed
        include Tms::Mixins::Columnable
        
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(mod)
          @mod = mod
          @used_in = process_used_in
        end

        def call
          return nil unless mod.used?
          return nil unless used_in

          used_values
        end

        private

        attr_reader :mod, :used_in

        def used_values
          used_in.map{ |col, params| [col, Tms::Services::UniqueFieldValues.call(*params)] }.to_h
        end
      end
    end
  end
end
