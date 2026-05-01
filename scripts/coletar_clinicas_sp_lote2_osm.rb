require "net/http"
require "uri"
require "json"
require "csv"

LIMIT = 100
OFFSET = 50
OUTPUT = "storage/prospects/clinicas_odontologicas_sp_lote_002.csv"

query = <<~OVERPASS
[out:json][timeout:80];
area["ISO3166-2"="BR-SP"][admin_level=4]->.searchArea;
(
  node["amenity"="dentist"](area.searchArea);
  way["amenity"="dentist"](area.searchArea);
  relation["amenity"="dentist"](area.searchArea);
);
out center #{LIMIT};
OVERPASS

uri = URI("https://overpass-api.de/api/interpreter")
response = Net::HTTP.post_form(uri, { "data" => query })

unless response.is_a?(Net::HTTPSuccess)
  puts "Erro ao consultar Overpass: #{response.code}"
  puts response.body
  exit 1
end

data = JSON.parse(response.body)
elements = data.fetch("elements", [])

selected = elements.drop(OFFSET).first(50)

rows = selected.map do |element|
  tags = element["tags"] || {}

  lat = element["lat"] || element.dig("center", "lat")
  lon = element["lon"] || element.dig("center", "lon")

  street = tags["addr:street"]
  number = tags["addr:housenumber"]
  bairro = tags["addr:suburb"] || tags["addr:neighbourhood"]
  city = tags["addr:city"] || tags["addr:municipality"]

  address = [street, number, bairro, city, "SP"].compact.reject(&:empty?).join(", ")

  {
    "ordem" => nil,
    "nome" => tags["name"].to_s.strip,
    "telefone" => tags["phone"].to_s.strip,
    "whatsapp" => tags["contact:whatsapp"].to_s.strip,
    "site" => (tags["website"] || tags["contact:website"]).to_s.strip,
    "email" => (tags["email"] || tags["contact:email"]).to_s.strip,
    "endereco" => address,
    "cidade" => city.to_s.strip,
    "bairro" => bairro.to_s.strip,
    "latitude" => lat,
    "longitude" => lon,
    "fonte" => "OpenStreetMap",
    "osm_tipo" => element["type"],
    "osm_id" => element["id"]
  }
end

rows = rows.each_with_index.map do |row, index|
  row["ordem"] = index + 1
  row
end

CSV.open(OUTPUT, "w", write_headers: true, headers: rows.first&.keys || []) do |csv|
  rows.each { |row| csv << row }
end

puts "Arquivo criado com sucesso:"
puts OUTPUT
puts "Total no lote 2: #{rows.size}"
puts "Atribuição: dados © OpenStreetMap contributors, licença ODbL."
