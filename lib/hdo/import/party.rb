module Hdo
  module Import
    class Party < Type
      FIELDS = [
        Import.external_id_field,
        Field.new(:name, true, :string, 'The name of the party.'),
      ]

      DESC = 'a political party'
      XML_EXAMPLE = <<-XML
<party>
  <externalId>DEM</externalId>
  <name>Democratic Party</name>
</party>
      XML

      def self.import(doc)
        doc.css("party").each do |party|
          p = ::Party.find_or_create_by_external_id party.css("externalId").text
          p.update_attributes! :name => party.css("name").text

          print "."
        end

      end

    end
  end
end
