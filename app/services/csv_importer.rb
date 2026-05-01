require "csv"

class CsvImporter
  def initialize(db)
    @db = db
  end

  def import_contacts(file_path)
    total = 0
    errors = []

    CSV.foreach(file_path, headers: true) do |row|
      begin
        name = row["nome"].to_s.strip
        phone = row["telefone"].to_s.strip
        procedure_name = row["procedimento"].to_s.strip
        notes = row["observacoes"].to_s.strip

        if name.empty? || phone.empty?
          errors << "Linha #{total + 2}: nome ou telefone vazio"
          next
        end

        @db[:contacts].insert(
          name: name,
          phone: phone,
          procedure_name: procedure_name,
          status: "novo",
          notes: notes,
          created_at: Time.now,
          updated_at: Time.now
        )

        total += 1
      rescue => e
        errors << "Linha #{total + 2}: #{e.message}"
      end
    end

    {
      total: total,
      errors: errors
    }
  end
end
