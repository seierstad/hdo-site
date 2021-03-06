# encoding: utf-8
require 'builder'

module Hdo
  module Import
    class Representative < Type
      FIELDS = [
        Import.external_id_field,
        Field.new(:firstName, true, :string, 'The first name of the representative.'),
        Field.new(:lastName, true, :string, 'The last name of the representative.'),
        Field.new(:period, true, :string, "An identifier for the period the representative is elected for."),
        Field.new(:district, true, :string, "The electoral district the representative belongs to. Must match the 'name' field of the district type."),
        Field.new(:party, true, :string, "The name of the representative's party."),
        Field.new(:committee, true, :list, "A (possibly empty) list of committees the representative is a member of. This should match the 'name' field of the committee type."),
        Field.new(:dateOfBirth, true, :string, "The representative's birth date."),
        Field.new(:dateOfDeath, false, :string, "The representative's death date."),
      ]

      DESC = 'a member of parliament'
      XML_EXAMPLE = <<-XML
<representative>
  <externalId>DD</externalId>
  <firstName>Donald</firstName>
  <lastName>Duck</lastName>
  <district>Duckburg</district>
  <party>Democratic Party</party>
  <committees>
    <committe>A</committe>
    <committe>B</committe>
  </committes>
  <period>2011-2012</period>
  <dateOfBirth>1969-04-04T00:00:00</dateOfBirth>
  <dateOfDeath>1969-04-04T00:00:00</dateOfDeath>
</representative>
      XML

      def self.xml_example(extras = {})
        xml = Builder::XmlMarkup.new :indent => 2
        xml.representative { |rep|
          rep.externalId "DD"
          rep.firstName "Donald"
          rep.lastName "Duck"
          rep.district "Duckburg"
          rep.party "Democratic Party"

          rep.committees { |coms|
            coms.committe "A"
            coms.committe "B"
          }

          rep.period "2011-2012"
          rep.dateOfBirth "1969-04-04T00:00:00"
          rep.dateOfDeath "0001-01-01T00:00:00"

          extras.each { |key, value|
            rep.__send__(key, value)
          }
        }

        xml.target!
      end

      def self.from(node)
        # assumes externalId is unique
        xid = node.css("externalId").first.text
        rep = ::Representative.find_by_external_id xid

        unless rep
          rep = ::Representative.find_by_external_id external_id_from(xid)
        end

        unless rep
          rep = import_representative node
        end

        rep
      end

      def self.import(doc)
        doc.css("representative").map do |rep|
          import_representative(rep)
          print "."
        end
      end

      def self.import_representative(node)
        external_id     = node.css("externalId").first.text
        party_name      = node.css("party").first.text
        first_name      = node.css("firstName").first.text
        last_name       = node.css("lastName").first.text
        committee_names = node.css("committees committee").map { |e| e.text }
        district_name   = node.css("district").first.text
        dob             = Time.parse(node.css("dateOfBirth").first.text)


        dod_node = node.css("dateOfDeath").first
        if dod_node
          dod = Time.parse(dod_node.text)
          dod = nil if dod.year == 1
        else
          dod = nil
        end

        party = ::Party.find_by_name!(party_name)
        committees = committee_names.map { |name| ::Committee.find_by_name!(name) }
        district = ::District.find_by_name!(district_name)

        rec = ::Representative.find_or_create_by_external_id external_id
        rec.update_attributes!(
          :party         => party,
          :first_name    => first_name,
          :last_name     => last_name,
          :committees    => committees,
          :district      => district,
          :date_of_birth => dob,
          :date_of_death => dod
        )

        rec
      end

      ID_CONVERSIONS = {
        'Æ' => '_AE',
        'Ø' => '_O',
        'Å' => '_A'
      }

      def self.query_param_from(external_id)
        xid = external_id.dup
        ID_CONVERSIONS.each { |k, v| xid.gsub!(k, v) }

        xid
      end

      def self.external_id_from(query_param)
        q = query_param.dup
        ID_CONVERSIONS.invert.each { |k, v| q.gsub!(k, v) }

        q
      end

    end
  end
end
