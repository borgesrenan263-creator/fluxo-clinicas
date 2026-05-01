require "sequel"
require "sqlite3"

DB = Sequel.sqlite("db/fluxo_clinicas.sqlite3")

templates = [
  {
    step: 1,
    title: "Primeira reativação",
    body: "Oi, [Nome], tudo bem? Vi que você tinha interesse em [Procedimento]. Temos alguns horários disponíveis essa semana. Quer que eu veja uma opção para você?",
    delay_hours: 0
  },
  {
    step: 2,
    title: "Lembrete leve",
    body: "Passando para lembrar, [Nome], que ainda podemos te ajudar com [Procedimento]. Se quiser, posso te mandar os horários livres de hoje e amanhã.",
    delay_hours: 24
  },
  {
    step: 3,
    title: "Última tentativa",
    body: "Última mensagem para não te incomodar 😊 Se ainda fizer sentido cuidar disso, posso reservar um horário rápido para você. Quer que eu te envie as opções?",
    delay_hours: 48
  }
]

templates.each do |template|
  exists = DB[:message_templates].where(step: template[:step]).count > 0
  next if exists

  DB[:message_templates].insert(
    step: template[:step],
    title: template[:title],
    body: template[:body],
    delay_hours: template[:delay_hours],
    active: 1,
    created_at: Time.now,
    updated_at: Time.now
  )
end

puts "Templates padrão criados com sucesso."
