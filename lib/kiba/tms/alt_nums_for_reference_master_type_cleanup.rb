# frozen_string_literal: true

module Kiba
  module Tms
    module AltNumsForReferenceMasterTypeCleanup
      module_function

      extend Dry::Configurable

      setting :base_job,
        default: :alt_nums__types_for_reference_master,
        reader: true

      setting :fingerprint_fields,
        default: Tms::AltNumsTypeCleanupShared.clean_fingerprint_fields,
        reader: true

      extend Kiba::Extend::Mixins::IterativeCleanup
      extend Tms::AltNumsTypeCleanupShared

      def job_tags
        Tms::AltNumsTypeCleanupShared.cleanup_job_tags(:reference_master)
      end
    end
  end
end
