require "sinatra"
require "sequel"
require "json"
require "csv"
require "prawn"
require "bcrypt"
require "dotenv/load"
require_relative "app/services/csv_importer"
require_relative "app/services/message_scheduler"
require_relative "app/services/response_registrar"

require_relative "config/database"

set :bind, "0.0.0.0"
set :port, ENV.fetch("PORT", 4567)
set :public_folder, File.expand_path("app/public", __dir__)
set :views, File.expand_path("app/views", __dir__)

helpers do
  def h(text)
    Rack::Utils.escape_html(text.to_s)
  end

  def status_label(status)
    labels = {
      "novo" => "Novo",
      "mensagem_1_enviada" => "Mensagem 1 enviada",
      "mensagem_2_enviada" => "Mensagem 2 enviada",
      "mensagem_3_enviada" => "Mensagem 3 enviada",
      "respondeu" => "Respondeu",
      "interessado" => "Interessado",
      "agendar" => "Quer agendar",
      "sem_interesse" => "Sem interesse",
      "nao_perturbar" => "Não perturbar",
      "convertido" => "Convertido",
      "perdido" => "Perdido"
    }

    labels[status.to_s] || status.to_s
  end
end

before do
  content_type :html
end

get "/" do
  @total_contacts = DB[:contacts].count
  @interested = DB[:contacts].where(status: "interessado").count
  @schedule = DB[:contacts].where(status: "agendar").count
  @converted = DB[:contacts].where(status: "convertido").count
  @contacts = DB[:contacts].reverse_order(:id).limit(20).all

  erb :dashboard
end

get "/contacts" do
  @contacts = DB[:contacts].reverse_order(:id).all
  erb :contacts
end

get "/contacts/new" do
  erb :new_contact
end

post "/contacts" do
  DB[:contacts].insert(
    name: params[:name],
    phone: params[:phone],
    procedure_name: params[:procedure_name],
    status: "novo",
    notes: params[:notes],
    created_at: Time.now,
    updated_at: Time.now
  )

  redirect "/contacts"
end

post "/contacts/:id/status" do
  DB[:contacts].where(id: params[:id]).update(
    status: params[:status],
    updated_at: Time.now
  )

  redirect "/contacts"
end

post "/contacts/:id/delete" do
  DB[:contacts].where(id: params[:id]).delete
  redirect "/contacts"
end

get "/campaigns" do
  @templates = DB[:message_templates].order(:step).all
  erb :campaigns
end

post "/campaigns/templates" do
  DB[:message_templates].insert(
    step: params[:step].to_i,
    title: params[:title],
    body: params[:body],
    delay_hours: params[:delay_hours].to_i,
    active: 1,
    created_at: Time.now,
    updated_at: Time.now
  )

  redirect "/campaigns"
end

post "/campaigns/templates/:id/delete" do
  DB[:message_templates].where(id: params[:id]).delete
  redirect "/campaigns"
end

get "/reports" do
  @total_contacts = DB[:contacts].count
  @total_messages = DB[:messages].count
  @sent_messages = DB[:messages].where(status: "enviada").count
  @responses_count = DB[:conversations].count

  @interested = DB[:contacts].where(status: "interessado").count
  @schedule = DB[:contacts].where(status: "agendar").count
  @converted = DB[:contacts].where(status: "convertido").count

  @response_rate = @total_contacts > 0 ? ((@responses_count.to_f / @total_contacts) * 100).round(1) : 0
  @interest_rate = @total_contacts > 0 ? (((@interested + @schedule + @converted).to_f / @total_contacts) * 100).round(1) : 0
  @conversion_rate = @total_contacts > 0 ? ((@converted.to_f / @total_contacts) * 100).round(1) : 0

  @by_status = DB[:contacts]
    .select_group(:status)
    .select_append { count(id).as(total) }
    .all

  erb :reports
end

get "/reports/pdf" do
  filename = "storage/reports/relatorio-fluxo-clinicas.pdf"

  total_contacts = DB[:contacts].count
  total_messages = DB[:messages].count
  sent_messages = DB[:messages].where(status: "enviada").count
  responses_count = DB[:conversations].count

  interested = DB[:contacts].where(status: "interessado").count
  schedule = DB[:contacts].where(status: "agendar").count
  converted = DB[:contacts].where(status: "convertido").count

  response_rate = total_contacts > 0 ? ((responses_count.to_f / total_contacts) * 100).round(1) : 0
  interest_rate = total_contacts > 0 ? (((interested + schedule + converted).to_f / total_contacts) * 100).round(1) : 0
  conversion_rate = total_contacts > 0 ? ((converted.to_f / total_contacts) * 100).round(1) : 0

  by_status = DB[:contacts]
    .select_group(:status)
    .select_append { count(id).as(total) }
    .all

  Prawn::Document.generate(filename) do |pdf|
    pdf.text "Relatório - Fluxo Clínicas", size: 22, style: :bold
    pdf.move_down 8
    pdf.text "Automação ética de reativação, atendimento e relatório", size: 10
    pdf.move_down 8
    pdf.text "Gerado em: #{Time.now.strftime("%d/%m/%Y %H:%M")}", size: 10

    pdf.move_down 22
    pdf.text "Resumo geral", size: 16, style: :bold
    pdf.move_down 10

    metrics = [
      ["Total de contatos", total_contacts],
      ["Mensagens geradas", total_messages],
      ["Mensagens enviadas", sent_messages],
      ["Respostas recebidas", responses_count],
      ["Interessados", interested],
      ["Querem agendar", schedule],
      ["Convertidos", converted],
      ["Taxa de resposta", "#{response_rate}%"],
      ["Taxa de interesse", "#{interest_rate}%"],
      ["Taxa de conversão", "#{conversion_rate}%"]
    ]

    metrics.each do |label, value|
      pdf.text "#{label}: #{value}", size: 11
      pdf.move_down 4
    end

    pdf.move_down 20
    pdf.text "Contatos por status", size: 16, style: :bold
    pdf.move_down 10

    by_status.each do |row|
      pdf.text "#{status_label(row[:status])}: #{row[:total]}", size: 11
      pdf.move_down 4
    end

    pdf.move_down 20
    pdf.text "Boas práticas", size: 16, style: :bold
    pdf.move_down 8
    pdf.text "Use apenas contatos legítimos da própria clínica ou empresa.", size: 10
    pdf.text "Respeite pedidos de pausa, remoção ou não perturbar.", size: 10
    pdf.text "Evite mensagens excessivas ou promessas de resultado.", size: 10
  end

  send_file filename, filename: "relatorio-fluxo-clinicas.pdf", type: "application/pdf"
end

get "/health" do
  content_type :json
  { status: "ok", app: "fluxo-clinicas", time: Time.now }.to_json
end

get "/imports" do
  @imports_dir = "storage/imports"
  @files = Dir.glob("#{@imports_dir}/*.csv").map { |file| File.basename(file) }
  erb :imports
end

post "/imports/run" do
  filename = params[:filename].to_s
  safe_filename = File.basename(filename)
  file_path = File.join("storage/imports", safe_filename)

  unless File.exist?(file_path)
    @message = "Arquivo não encontrado: #{safe_filename}"
    @result = nil
    return erb :import_result
  end

  importer = CsvImporter.new(DB)
  @result = importer.import_contacts(file_path)
  @message = "Importação finalizada."

  erb :import_result
end

get "/messages" do
  @messages = DB.fetch(
    """
    SELECT
      messages.id AS id,
      contacts.id AS contact_id,
      contacts.name AS contact_name,
      contacts.phone AS phone,
      message_templates.step AS step,
      messages.body AS body,
      messages.status AS status,
      messages.scheduled_at AS scheduled_at,
      messages.sent_at AS sent_at
    FROM messages
    INNER JOIN contacts ON contacts.id = messages.contact_id
    INNER JOIN message_templates ON message_templates.id = messages.template_id
    ORDER BY messages.id DESC
    """
  ).all

  erb :messages
end

post "/messages/schedule" do
  scheduler = MessageScheduler.new(DB)
  @result = scheduler.schedule_for_all_contacts
  erb :schedule_result
end

post "/messages/:id/mark_sent" do
  DB[:messages].where(id: params[:id]).update(
    status: "enviada",
    sent_at: Time.now,
    updated_at: Time.now
  )

  redirect "/messages"
end

post "/messages/:id/mark_failed" do
  DB[:messages].where(id: params[:id]).update(
    status: "falhou",
    updated_at: Time.now
  )

  redirect "/messages"
end

get "/responses/new/:contact_id" do
  @contact = DB[:contacts].where(id: params[:contact_id]).first

  unless @contact
    halt 404, "Contato não encontrado"
  end

  erb :new_response
end

post "/responses" do
  registrar = ResponseRegistrar.new(DB)

  registrar.register(
    contact_id: params[:contact_id].to_i,
    body: params[:body],
    classification: params[:classification]
  )

  redirect "/contacts"
end

get "/responses" do
  @responses = DB.fetch(
    """
    SELECT
      conversations.id AS id,
      contacts.name AS contact_name,
      contacts.phone AS phone,
      conversations.body AS body,
      conversations.classification AS classification,
      conversations.created_at AS created_at
    FROM conversations
    INNER JOIN contacts ON contacts.id = conversations.contact_id
    ORDER BY conversations.id DESC
    """
  ).all

  erb :responses
end
