require "csv"
require "digest"

class ProspectImporter
  def initialize(db)
    @db = db
  end

  def import_csv(file_path, limit: 50)
    created = 0
    skipped = 0
    errors = []

    rows = CSV.read(file_path, headers: true)

    rows.first(limit).each_with_index do |row, index|
      begin
        name = pick(row, "nome", "name")
        phone = pick(row, "telefone", "phone")
        whatsapp = pick(row, "whatsapp")
        website = pick(row, "site", "website")
        email = pick(row, "email")
        city = pick(row, "cidade", "city")
        neighborhood = pick(row, "bairro", "neighborhood")
        address = pick(row, "endereco", "address")
        source = pick(row, "fonte", "source")
        source_type = pick(row, "osm_tipo", "source_type")
        source_id = pick(row, "osm_id", "source_id")
        notes = pick(row, "observacoes", "notes")

        if name.empty? && address.empty?
          skipped += 1
          next
        end

        dedupe_key = build_dedupe_key(
          name: name,
          phone: phone,
          whatsapp: whatsapp,
          city: city,
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
          city: city,
          address: address
        )
          skipped += 1
          next
        end

        now = Time.now

        @db[:prospects].insert(
          name: name,
          phone: phone,
          whatsapp: whatsapp,
          website: website,
          email: email,
          city: city,
          neighborhood: neighborhood,
          address: address,
          source: source.empty? ? "CSV" : source,
          source_type: source_type,
          source_id: source_id,
          dedupe_key: dedupe_key,
          status: "novo",
          notes: notes,
          created_at: now,
          updated_at: now
        )

        created += 1
      rescue => e
        errors << "Linha #{index + 2}: #{e.message}"
      end
    end

    {
      created: created,
      skipped: skipped,
      errors: errors
    }
  end

  private

  def pick(row, *names)
    names.each do |name|
      value = row[name]
      return value.to_s.strip if value && !value.to_s.strip.empty?
    end

    ""
  end

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
    clean = clean_phone(whatsapp.empty? ? phone : whatsapp)

    if !clean.empty?
      raw = "phone:#{clean}"
    elsif source_id && !source_id.to_s.strip.empty?
      raw = "source:#{source}|#{source_type}|#{source_id}"
    else
      raw = "name_city_address:#{normalize(name)}|#{normalize(city)}|#{normalize(address)}"
    end

    Digest::SHA256.hexdigest(raw)
  end

  def duplicate_exists?(dedupe_key:, name:, phone:, whatsapp:, city:, address:)
    return true if @db[:prospects].where(dedupe_key: dedupe_key).count > 0

    clean = clean_phone(whatsapp.empty? ? phone : whatsapp)

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
