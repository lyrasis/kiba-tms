# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjInsIndemResp
      module_function

      extend Dry::Configurable

      # whether or not table is used
      setting :used, default: ->{ Tms::Tables::List.include?('ObjInsIndemResp') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[tableid], reader: true
      setting :empty_fields, default: %i[], reader: true
      setting :empty_pattern, default: '^0|\.0000|$', reader: true

      setting :indemnity_fields, default: %i[], reader: true
      setting :insurance_fields, default: %i[], reader: true
      
      setting :fieldlabel, reader: true do
        setting :indematvenue, default: 'Indemnity responsibility at venue site', reader: true
        setting :indemreturn, default: 'Indemnity responsibility for return to lender', reader: true
        setting :indemtovenuefromlender,
          default: 'Indemnity responsibility for transit if objects travels from lender to its first venue',
          reader: true
        setting :indemtovenuefromvenue,
          default: 'Indemnity responsibility for transit if objects travels from previous venue to venue',
          reader: true
        setting :insatvenue, default: 'Insurance responsibility at venue site', reader: true
        setting :insreturn, default: 'Insurance responsibility for return to lender', reader: true
        setting :instovenuefromlender,
          default: 'Insurance responsibility for transit if objects travels from lender to its first venue',
          reader: true
        setting :instovenuefromvenue,
          default: 'Insurance responsibility for transit if objects travels from previous venue to venue',
          reader: true
      end

      def ins_ind_fields
        ( indemnity_fields + insurance_fields ).uniq
      end
      
      def omitted_fields
        ( delete_fields + empty_fields ).uniq
      end
    end
  end
end

