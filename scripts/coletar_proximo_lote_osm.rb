require "net/http"
require "uri"
require "json"
require "csv"
require "set"
require_relative "../config/database"

BATCH_SIZE = (ENV["BATCH_SIZE"] || "50").to_i
FETCH_LIMIT = (ENV["FETCH_LIMIT"] || "300").to_i

Dir.mkdir("storage/prospects") unless Dir.exist?("storage/prospects")

existing_source_keys = DB[:prospects].all.map do |p|
  [
    p[:source].to_s,
    p[:source_type].to_s,
    p[:source_id].to_s
  ].join("|")
end.to_set

existing_phones = DB[:prospects].all.map do |p|
  phone = p[:whatsapp].to_s.empty? ? p[:phone].to_s : p[:whatsapp].to_s
  phone.gsub(/\D/, "")
end.reject(&:empty?).to_set

existing_name_city_address = DB[:prospects].all.map do |p|
  [
    p[:name].to_s.downcase.gsub(/[^\p{Alnum}\s]/, "").gsub(/\s+/, " ").strip,
    p[:city].to_s.downcase.gsub(/[^\p{Alnum}\s]/, "").gsub(/\s+/, " ").strip,
    p[:address].to_s.downcase.gsub(/[^\p{Alnum}\s]/, "").gsub(/\s+/, " ").strip
  ].join("|")
end.to_set

query = <<~OVERPASS
[out:json][timeout:90];
area["ISO3166-2"="BR-SP"][admin_level=4]->.searchArea;
(
  node["amenity"="dentist"](area.searchArea);
  way["amenity"="dentist"](area.searchArea);
  relation["amenity"="dentist"](area.searchArea);
);
out center #{FETCH_LIMIT};
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

rows = []

elements.each do |element|
  tags = element["tags"] || {}

  lat = element["lat"] || element.dig("center", "lat")
  lon = element["lon"] || element.dig("center", "lon")

  street = tags["addr:street"]
  number = tags["addr:housenumber"]
  bairro = tags["addr:suburb"] || tags["addr:neighbourhood"]
  city = tags["addr:city"] || tags["addr:municipality"]

  address = [street, number, bairro, city, "SP"].compact.reject(&:empty?).join(", ")

  name = tags["name"].to_s.strip
  phone = tags["phone"].to_s.strip
  whatsapp = tags["contact:whatsapp"].to_s.strip
  source = "OpenStreetMap"
  source_type = element["type"].to_s
  source_id = element["id"].to_s

  source_key = [source, source_type, source_id].join("|")
  clean_phone = (whatsapp.empty? ? phone : whatsapp).gsub(/\D/, "")

  normalized_identity = [
    name.downcase.gsub(/[^\p{Alnum}\s]/, "").gsub(/\s+/, " ").strip,
    city.to_s.downcase.gsub(/[^\p{Alnum}\s]/, "").gsub(/\s+/, " ").strip,
    address.to_s.downcase.gsub(/[^\p{Alnum}\s]/, "").gsub(/\s+/, " ").strip
  ].join("|")

  next if existing_source_keys.include?(source_key)
  next if !clean_phone.empty? && existing_phones.include?(clean_phone)
  next if existing_name_city_address.include?(normalized_identity)

  rows << {
    "ordem" => rows.size + 1,
    "nome" => name,
    "telefone" => phone,
    "whatsapp" => whatsapp,
    "site" => (tags["website"] || tags["contact:website"]).to_s.strip,
    "email" => (tags["email"] || tags["contact:email"]).to_s.strip,
    "endereco" => address,
    "cidade" => city.to_s.strip,
    "bairro" => bairro.to_s.strip,
    "latitude" => lat,
    "longitude" => lon,
    "fonte" => source,
    "osm_tipo" => source_type,
    "osm_id" => source_id
  }

  break if rows.size >= BATCH_SIZE
end

existing_batches = Dir.glob("storage/prospects/clinicas_odontologicas_sp_lote_*.csv").map do |file|
  File.basename(file).scan(/lote_(\d+)/).flatten.first.to_i
end

batch_number = existing_batches.empty? ? 1 : existing_batches.max + 1
output = "storage/prospects/clinicas_odontologicas_sp_lote_#{batch_number.to_s.rjust(3, "0")}.csv"

CSV.open(output, "w", write_headers: true, headers: [
  "ordem",
  "nome",
  "telefone",
  "whatsapp",
  "site",
  "email",
  "endereco",
  "cidade",
  "bairro",
  "latitude",
  "longitude",
  "fonte",
  "osm_tipo",
  "osm_id"
]) do |csv|
  rows.each { |row| csv << row }
end

puts "Arquivo criado:"
puts output
puts "Novos prospects no CSV: #{rows.size}"
puts "Base atual no banco: #{DB[:prospects].count}"
puts "Atribuição: dados © OpenStreetMap contributors, licença ODbL."
