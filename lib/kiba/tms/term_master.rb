# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TermMaster
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :tms__term_master_thes, reader: true
      setting :delete_fields,
        default: %i[dateentered datemodified termclassid displaydescriptorid],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
