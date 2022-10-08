# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module NameTypeCleanup
      module_function

      extend Dry::Configurable

      setting :source_job_key,
        default: :name_type_cleanup__from_base_data,
        reader: true

      extend Tms::Mixins::Tableable

      def used?
        true
      end

      # Indicates whether any cleanup has been returned. If not, we run
      #   everything on base data. If yes, we merge in/overlay cleanup on the
      #   affected base data tables
      setting :done, default: false, reader: true

      setting :untyped_treatment,
        default: 'Person',
        reader: true

      setting :targets, default: [], reader: true

      setting :configurable, default: {
        targets: proc{ Tms::Services::NameTypeCleanup::TargetsDeriver.call }
      },
        reader: true

      def initial_headers
        base = %i[name correctname authoritytype correctauthoritytype termsource]
        base.unshift(:to_review) if Tms::Names.cleanup_iteration
        base
      end

    end
  end
end
