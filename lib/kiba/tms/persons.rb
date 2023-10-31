# frozen_string_literal: true

module Kiba
  module Tms
    module Persons
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :name_compile__persons,
        reader: true
      extend Tms::Mixins::Tableable

      setting :bionote_sources,
        default: %i[biography rel_name_bio_note],
        reader: true
      setting :group_sources,
        default: [:culturegroup],
        reader: true
      setting :namenote_sources,
        default: %i[remarks address_namenote email_web_namenote
          phone_fax_namenote text_entry],
        reader: true
      setting :term_targets,
        default: %i[termdisplayname salutation title forename
          middlename surname nameadditions termflag
          termsourcenote],
        reader: true,
        constructor: ->(value) do
          value << :termsource if Tms::Names.set_term_source
          value << :termprefforlang if Tms::Names.set_term_pref_for_lang
          value
        end
      setting :cs_fields,
        default: {
          fcart: %i[
            termdisplayname termname termqualifier termstatus termtype termflag
            termlanguage termprefforlang salutation title forename middlename
            surname nameadditions initials termsourcecitationlocal
            termsourcecitationworldcat termsourcedetail termsourceid
            termsourcenote gender occupation schoolorstyle group nationality
            namenote birthdategroup birthplace deathdategroup deathplace bionote
            email emailtype telephonenumber telephonenumbertype faxnumber
            faxnumbertype webaddress webaddresstype addressplace1 addressplace2
            addressmunicipality addressstateorprovince addresspostcode
            addresscountry addresstype declinedtoanswerpronoun suppliedpronoun
            userestrictionpronoun declinedtoanswergender suppliedgender
            userestrictiongender declinedtoanswerrace suppliedrace
            userestrictionrace declinedtoanswerethnicity suppliedethnicity
            userestrictionethnicity declinedtoanswersexuality suppliedsexuality
            userestrictionsexuality declinedtoanswerbirthplace
            suppliedbirthplace userestrictionbirthplace
            declinedtoanswerbirthdate suppliedstructuredbirthdategroup
            userestrictionbirthdate informationauthor informationdate
            informationuserestriction otherinformation
          ]
        },
        reader: true
    end
  end
end
