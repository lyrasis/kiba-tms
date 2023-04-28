# frozen_string_literal: true

module Kiba
  module Tms
    module ConservationTreatments
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :cs_fields,
        default: %i[conservationnumber status statusdate treatmentpurpose
                    conservatorpersonlocal conservatororganizationlocal
                    otherpartypersonlocal otherpartyorganizationlocal
                    otherpartyrole otherpartynote examinationstaff
                    examinationphase examinationdate examinationnote
                    fabricationnote proposedtreatment approvedby approveddate
                    treatmentstartdate treatmentenddate treatmentsummary
                    proposedanalysis researcher proposedanalysisdate
                    destanalysisapproveddate destanalysisapprovalnote sampleby
                    sampledate sampledescription samplereturned
                    samplereturnedlocation analysismethod analysisresults],
        reader: true
    end
  end
end
