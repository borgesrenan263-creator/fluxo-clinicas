require_relative "../config/database"

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

puts "Banco verificado/criado com sucesso."
puts "Adaptador usado: #{DB.database_type}"

unless DB.table_exists?(:prospects)
  DB.create_table :prospects do
    primary_key :id
    String :name
    String :phone
    String :whatsapp
    String :website
    String :email
    String :city
    String :neighborhood
    Text :address
    String :source
    String :source_type
    String :source_id
    String :dedupe_key
    String :status, default: "novo"
    Text :notes
    DateTime :last_contacted_at
    DateTime :responded_at
    DateTime :confirmed_at
    DateTime :archived_at
    DateTime :do_not_contact_until
    DateTime :created_at
    DateTime :updated_at

    index :dedupe_key, unique: true
    index :status
    index :do_not_contact_until
  end
end

unless DB.table_exists?(:prospect_events)
  DB.create_table :prospect_events do
    primary_key :id
    foreign_key :prospect_id, :prospects
    String :event_type
    Text :body
    DateTime :created_at
  end
end

company_columns = DB.schema(:companies).map { |column| column[0] }

unless company_columns.include?(:prospect_id)
  DB.alter_table(:companies) do
    add_column :prospect_id, Integer
  end
end

puts "Tabelas de Prospects B2B verificadas/criadas com sucesso."
