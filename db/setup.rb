require "sequel"
require "sqlite3"

DB = Sequel.sqlite("db/fluxo_clinicas.sqlite3")

unless DB.table_exists?(:contacts)
  DB.create_table :contacts do
    primary_key :id
    String :name, null: false
    String :phone, null: false
    String :procedure_name
    String :status, default: "novo"
    Text :notes
    DateTime :created_at
    DateTime :updated_at
  end
end

unless DB.table_exists?(:message_templates)
  DB.create_table :message_templates do
    primary_key :id
    Integer :step, null: false
    String :title, null: false
    Text :body, null: false
    Integer :delay_hours, default: 24
    Integer :active, default: 1
    DateTime :created_at
    DateTime :updated_at
  end
end

unless DB.table_exists?(:messages)
  DB.create_table :messages do
    primary_key :id
    foreign_key :contact_id, :contacts
    foreign_key :template_id, :message_templates
    Text :body
    String :status, default: "pendente"
    DateTime :scheduled_at
    DateTime :sent_at
    DateTime :created_at
    DateTime :updated_at
  end
end

unless DB.table_exists?(:companies)
  DB.create_table :companies do
    primary_key :id
    String :name, null: false
    String :phone
    String :email
    String :plan_name
    String :payment_status, default: "pendente"
    DateTime :created_at
    DateTime :updated_at
  end
end

puts "Banco criado/atualizado com sucesso."

unless DB.table_exists?(:conversations)
  DB.create_table :conversations do
    primary_key :id
    foreign_key :contact_id, :contacts
    String :direction, default: "entrada"
    Text :body
    String :classification
    DateTime :created_at
    DateTime :updated_at
  end
end

puts "Tabela conversations verificada/criada com sucesso."
