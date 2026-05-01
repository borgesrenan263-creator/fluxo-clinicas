require_relative "../config/database"
require "date"

items = [
  ["income", "Mensalidade", "Mensalidade clínica Alpha", 49700, Date.today - 10, "Pix", "confirmado"],
  ["income", "Setup inicial", "Setup inicial clínica Beta", 69700, Date.today - 7, "Pix", "confirmado"],
  ["income", "Campanha avulsa", "Campanha de reativação", 29700, Date.today - 3, "Pix", "pendente"],
  ["expense", "Hospedagem", "Servidor Render/Railway", 5900, Date.today - 12, "Cartão", "confirmado"],
  ["expense", "Domínio", "Domínio anual", 4000, Date.today - 20, "Pix", "confirmado"],
  ["expense", "Ferramentas", "Ferramentas de operação", 9900, Date.today - 5, "Cartão", "pendente"]
]

items.each do |kind, category, description, amount_cents, date, method, status|
  exists = DB[:finance_transactions].where(description: description).count > 0
  next if exists

  DB[:finance_transactions].insert(
    kind: kind,
    category: category,
    description: description,
    amount_cents: amount_cents,
    transaction_date: date,
    payment_method: method,
    status: status,
    notes: "Seed financeiro de demonstração",
    created_at: Time.now,
    updated_at: Time.now
  )
end

puts "Seed financeiro criado com sucesso."
