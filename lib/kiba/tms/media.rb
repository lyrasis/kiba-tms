# frozen_string_literal: true

module Kiba
  module Tms
    module Media
      extend Dry::Configurable

      setting :cs_record_id_field,
        default: :identificationnumber,
        reader: true

      setting :cs_fields,
        default: {
          fcart: %i[identificationnumber title publishto name mimetype
            length externalurl measuredpart dimensionsummary dimension
            measuredbypersonlocal measuredbyorganizationlocal
            measurementmethod value measurementunit valuequalifier
            valuedate measuredpartnote checksumvalue checksumtype
            checksumdate contributorpersonlocal
            contributororganizationlocal creatorpersonlocal
            creatororganizationlocal language publisherpersonlocal
            publisherorganizationlocal relation copyrightstatement
            type coverage dategroup source subject
            rightsholderpersonlocal rightsholderorganizationlocal
            description alttext mediafileuri]
        },
        reader: true,
        constructor: ->(val) { val[Tms.cspace_profile] }
      extend Tms::Mixins::CsTargetable

      module_function
    end
  end
end
