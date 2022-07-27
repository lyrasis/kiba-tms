# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class TmsTableNames
        def initialize(source: :tableid, target: :tablename)
          @source = source
          @target = target
          @lookup = {
            '23'=>'Constituents',
            '47'=>'Exhibitions',
            '49'=>'ExhObjXrefs',
            '51'=>'ExhVenuesXrefs',
            '79'=>'LoanObjXrefs',
            '81'=>'Loans',
            '89'=>'ObjAccession',
            '94'=>'ObjComponents',
            '95'=>'Conditions',
            '102'=>'ObjDeaccession',
            '108'=>'Objects',
            '126'=>'ObjRights',
            '143'=>'ReferenceMaster',
            '187'=>'HistEvents',
            '287'=>'TermMasterThes',
            '345'=>'Shipments',
            '355'=>'ShipmentSteps',
            '631'=>'AccessionLot',
            '632'=>'RegistrationSets',
            '726'=>'ObjContext'
          }
        end

        def process(row)
          row[@target] = nil
          tid = row.fetch(@source, nil)
          row.delete(@source)
          return row if tid.blank?

          row[@target] = table_name(tid)
          row
        end

        private

        def table_name(id)
          unless @lookup.key?(id)
            puts "#{Kiba::Extend.warning_label}: ID #{id} is not in #{self.class} lookup"
            return nil
          end

          @lookup[id]
        end
      end
    end
  end
end
