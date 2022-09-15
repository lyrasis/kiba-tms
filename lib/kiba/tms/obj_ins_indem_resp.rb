# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjInsIndemResp
      extend Dry::Configurable
      module_function

      setting :checkable,
        default: {
          all_fields_have_labels: Proc.new{ check_all_fields_have_labels }
        },
        reader: true
      
      setting :delete_fields, default: %i[tableid], reader: true
      setting :empty_fields, default: %i[], reader: true
      extend Tms::Mixins::Tableable

      setting :target_tables, default: %w[], reader: true
      extend Tms::Mixins::MultiTableMergeable
      
      setting :indemnity_fields,default: %i[], reader: true,
        constructor: Proc.new{ fields.select{ |f| f.to_s.start_with?('ind') } }
      setting :insurance_fields, default: %i[], reader: true,
        constructor: Proc.new{ fields.select{ |f| f.to_s.start_with?('ins') } }
      setting :fieldlabels,
        default: {
          indematvenue: 'Indemnity responsibility at venue site',    
          indemreturn: 'Indemnity responsibility for return to lender',
          indemtovenuefromlender: 'Indemnity responsibility for transit if objects travels from lender to its first venue',
          indemtovenuefromvenue: 'Indemnity responsibility for transit if objects travels from previous venue to venue',
          insatvenue: 'Insurance responsibility at venue site',
          insreturn: 'Insurance responsibility for return to lender',
          instovenuefromlender: 'Insurance responsibility for transit if objects travels from lender to its first venue',
          instovenuefromvenue: 'Insurance responsibility for transit if objects travels from previous venue to venue'
        },
        reader: true

      def ins_ind_fields
        ( indemnity_fields + insurance_fields ).uniq
      end

      def check_all_fields_have_labels
        missing_labels = ins_ind_fields.reject{ |field| fieldlabels.key?(field) }
        return if missing_labels.empty?

        "#{self.name}: Add labels for the following fields to `fieldlabels` :\n#{missing_labels.join(', ')}"
      end
    end
  end
end
