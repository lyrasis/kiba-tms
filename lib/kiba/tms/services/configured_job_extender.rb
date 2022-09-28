# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class ConfiguredJobExtender
        class << self
          def call(...)
            self.new(...).call
          end
        end

        # @param namespace [Symbol] a constant in the Tms::Jobs namespace
        # @param verbose [Boolean]
        def initialize(namespace:, verbose: false)
          @parent = Tms::Jobs.const_get(namespace)
          @jobs = parent.constants.map{ |const| parent.const_get(const) }
          @verbose = verbose
        end

        def call
          jobs.each{ |job| job.extend(Tms::Mixins::ConfiguredJob) }
          if verbose
            puts "#{parent}: extended #{jobs.length} jobs with :config"
          end
        end

        private

        attr_reader :parent, :jobs, :verbose
      end
    end
  end
end
