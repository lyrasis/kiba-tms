# frozen_string_literal: true

module Kiba
  module Tms
    module AltNumsForRefmasterTypeCleanup
      module_function

      extend Dry::Configurable

      setting :base_job,
        default: :alt_nums__types_for_reference_master,
        reader: true

      setting :fingerprint_fields,
        default: Tms::AltNumsCleanupShared.clean_fingerprint_fields,
        reader: true

      extend Kiba::Extend::Mixins::IterativeCleanup
      extend Tms::AltNumsCleanupShared

      def job_tags
        Tms::AltNumsCleanupShared.cleanup_job_tags(:reference_master)
      end
    end
  end
end
