require "net/http"
require "uri"
require "json"
require "digest"

class ProspectOsmCollector
  def initialize(db)
    @db = db
  end

  def collect_with_contact(limit: 50, fetch_limit: 1500)
    query = <<~OVERPASS
    [out:json][timeout:120];
    area["ISO3166-2"="BR-SP"][admin_level=4]->.searchArea;
    (
      node["amenity"="dentist"](area.searchArea);
      way["amenity"="dentist"](area.searchArea);
      relation["amenity"="dentist"](area.searchArea);
    );
    out center #{fetch_limit};
    OVERPASS

    uri = URI("https://overpass-api.de/api/interpreter")
    response = Net::HTTP.post_form(uri, { "data" => query })

    unless response.is_a?(Net::HTTPSuccess)
      return {
        created: 0,
        skipped: 0,
        error: "Erro ao consultar OpenStreetMap/Overpass: #{response.code}"
      }
    end

    data = JSON.parse(response.body)
    elements = data.fetch("elements", [])

    created = 0
    skipped = 0
    errors = []

    elements.each do |element|
      break if created >= limit

      begin
        tags = element["tags"] || {}

        phone = tags["phone"].to_s.strip
        whatsapp = tags["contact:whatsapp"].to_s.strip
        best_contact = whatsapp.empty? ? phone : whatsapp
        clean_contact = clean_phone(best_contact)

        if clean_contact.empty? || clean_contact.length < 10
          skipped += 1
          next
        end

        name = tags["name"].to_s.strip

        lat = element["lat"] || element.dig("center", "lat")
        lon = element["lon"] || element.dig("center", "lon")

        street = tags["addr:street"]
        number = tags["addr:housenumber"]
        neighborhood = tags["addr:suburb"] || tags["addr:neighbourhood"]
        city = tags["addr:city"] || tags["addr:municipality"]
        address = [street, number, neighborhood, city, "SP"].compact.reject(&:empty?).join(", ")

        source = "OpenStreetMap"
        source_type = element["type"].to_s
        source_id = element["id"].to_s

        dedupe_key = build_dedupe_key(
          name: name,
          phone: phone,
          whatsapp: whatsapp,
          city: city.to_s,
          address: address,
          source: source,
          source_type: source_type,
          source_id: source_id
        )

        if duplicate_exists?(
          dedupe_key: dedupe_key,
          name: name,
          phone: phone,
          whatsapp: whatsapp,
          city: city.to_s,
          address: address,
          source: source,
          source_type: source_type,
          source_id: source_id
        )
          skipped += 1
          next
        end

        now = Time.now

        @db[:prospects].insert(
          name: name,
          phone: phone,
          whatsapp: whatsapp,
          website: (tags["website"] || tags["contact:website"]).to_s.strip,
          email: (tags["email"] || tags["contact:email"]).to_s.strip,
          city: city.to_s.strip,
          neighborhood: neighborhood.to_s.strip,
          address: address,
          source: source,
          source_type: source_type,
          source_id: source_id,
          dedupe_key: dedupe_key,
          status: "novo",
          notes: "Importado automaticamente com contato público. Verificar manualmente antes de abordagem.",
          created_at: now,
          updated_at: now
        )

        created += 1
      rescue => e
        errors << e.message
        skipped += 1
      end
    end

    {
      created: created,
      skipped: skipped,
      errors: errors.uniq.first(10),
      error: nil
    }
  end

  private

  def normalize(value)
    value.to_s.downcase
      .gsub(/[^\p{Alnum}\s]/, "")
      .gsub(/\s+/, " ")
      .strip
  end

  def clean_phone(value)
    value.to_s.gsub(/\D/, "")
  end

  def build_dedupe_key(name:, phone:, whatsapp:, city:, address:, source:, source_type:, source_id:)
    clean = clean_phone(whatsapp.to_s.empty? ? phone : whatsapp)

    if !clean.empty?
      raw = "phone:#{clean}"
    elsif source_id && !source_id.to_s.strip.empty?
      raw = "source:#{source}|#{source_type}|#{source_id}"
    else
      raw = "name_city_address:#{normalize(name)}|#{normalize(city)}|#{normalize(address)}"
    end

    Digest::SHA256.hexdigest(raw)
  end

  def duplicate_exists?(dedupe_key:, name:, phone:, whatsapp:, city:, address:, source:, source_type:, source_id:)
    return true if @db[:prospects].where(dedupe_key: dedupe_key).count > 0

    source_match = @db[:prospects].where(
      source: source,
      source_type: source_type,
      source_id: source_id
    ).count > 0

    return true if source_match

    clean = clean_phone(whatsapp.to_s.empty? ? phone : whatsapp)

    if !clean.empty?
      phone_matches = @db[:prospects].all.any? do |prospect|
        existing_phone = clean_phone(prospect[:whatsapp].to_s.empty? ? prospect[:phone] : prospect[:whatsapp])
        existing_phone == clean
      end

      return true if phone_matches
    end

    normalized_name = normalize(name)
    normalized_city = normalize(city)
    normalized_address = normalize(address)

    @db[:prospects].all.any? do |prospect|
      normalize(prospect[:name]) == normalized_name &&
        normalize(prospect[:city]) == normalized_city &&
        normalize(prospect[:address]) == normalized_address
    end
  end
end
