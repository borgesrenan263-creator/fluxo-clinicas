require_relative "../config/database"

def normalize(value)
  value.to_s.downcase
    .gsub(/[^\p{Alnum}\s]/, "")
    .gsub(/\s+/, " ")
    .strip
end

def phone_key(prospect)
  phone = prospect[:whatsapp].to_s.empty? ? prospect[:phone].to_s : prospect[:whatsapp].to_s
  phone.gsub(/\D/, "")
end

def dedupe_identity(prospect)
  phone = phone_key(prospect)

  if !phone.empty?
    "phone:#{phone}"
  else
    name = normalize(prospect[:name])
    city = normalize(prospect[:city])
    address = normalize(prospect[:address])

    "name_city_address:#{name}|#{city}|#{address}"
  end
end

prospects = DB[:prospects].order(:id).all

groups = prospects.group_by { |prospect| dedupe_identity(prospect) }

removed = 0

groups.each do |_key, items|
  next if items.size <= 1

  keep = items.find { |p| p[:source].to_s.downcase.include?("openstreetmap") } || items.first
  duplicates = items.reject { |p| p[:id] == keep[:id] }

  duplicates.each do |duplicate|
    DB[:prospect_events].where(prospect_id: duplicate[:id]).update(prospect_id: keep[:id]) if DB.table_exists?(:prospect_events)

    DB[:prospects].where(id: duplicate[:id]).delete
    removed += 1

    puts "Removido duplicado ##{duplicate[:id]} mantendo ##{keep[:id]} - #{keep[:name]}"
  end
end

puts
puts "Limpeza finalizada."
puts "Duplicados removidos: #{removed}"
puts "Total atual de prospects: #{DB[:prospects].count}"
