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

        dedupe_key = build_dedupe_key(
          name: name,
          city: city,
          source: source,
          source_type: source_type,
          source_id: source_id
        )

        existing = @db[:prospects].where(dedupe_key: dedupe_key).first

        if existing
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
          notes: pick(row, "observacoes", "notes"),
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

  def build_dedupe_key(name:, city:, source:, source_type:, source_id:)
    if source_id && !source_id.to_s.strip.empty?
      raw = "#{source}|#{source_type}|#{source_id}"
    else
      raw = "#{name}|#{city}".downcase.gsub(/\s+/, " ").strip
    end

    Digest::SHA256.hexdigest(raw)
  end
end
