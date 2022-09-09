# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class RowCounter
        include Tms::Services::Runnable
        
        def initialize
        end

        def call(job_key)
          row_count(job_key)
        end

        private

      end
    end
  end
end
