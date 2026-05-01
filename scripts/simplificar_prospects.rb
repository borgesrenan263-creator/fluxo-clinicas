require "csv"

input = "storage/prospects/clinicas_odontologicas_sp_50.csv"
output = "storage/prospects/clinicas_odontologicas_sp_50_simplificado.csv"

rows = CSV.read(input, headers: true)

CSV.open(output, "w", write_headers: true, headers: [
  "ordem",
  "nome",
  "telefone",
  "whatsapp",
  "site",
  "cidade",
  "bairro",
  "endereco",
  "observacoes"
]) do |csv|
  rows.each do |row|
    csv << [
      row["ordem"],
      row["nome"],
      row["telefone"],
      row["whatsapp"],
      row["site"],
      row["cidade"],
      row["bairro"],
      row["endereco"],
      "Lead B2B público. Verificar manualmente antes de contato. Fonte: OpenStreetMap."
    ]
  end
end

puts "Arquivo simplificado criado:"
puts output
