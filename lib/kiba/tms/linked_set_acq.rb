# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LinkedSetAcq
      extend Dry::Configurable
      module_function

      setting :source_job_key,
        default: :linked_set_acq__rows,
        reader: true
      extend Tms::Mixins::Tableable

      def used?
        Tms::ObjAccession.processing_approaches.any?(:linkedset)
      end

    end
  end
end
