# frozen_string_literal: true

module Kiba
  module Tms
    module RelsAcqObj
      extend Dry::Configurable

      setting :rectype1,
        default: "Acquisitions",
        reader: true
      setting :rectype2,
        default: "Collectionobjects",
        reader: true
      setting :sample_from,
        default: :rectype1,
        reader: true

      extend Tms::Mixins::CsNonhierarchicalRelation

      module_function
    end
  end
end
