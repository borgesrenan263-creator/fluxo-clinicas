class ResponseRegistrar
  def initialize(db)
    @db = db
  end

  def register(contact_id:, body:, classification:)
    now = Time.now

    @db[:conversations].insert(
      contact_id: contact_id,
      direction: "entrada",
      body: body,
      classification: classification,
      created_at: now,
      updated_at: now
    )

    new_status = status_from_classification(classification)

    @db[:contacts].where(id: contact_id).update(
      status: new_status,
      updated_at: now
    )

    {
      contact_id: contact_id,
      status: new_status
    }
  end

  private

  def status_from_classification(classification)
    case classification.to_s
    when "interessado"
      "interessado"
    when "agendar"
      "agendar"
    when "sem_interesse"
      "sem_interesse"
    when "nao_perturbar"
      "nao_perturbar"
    when "convertido"
      "convertido"
    else
      "respondeu"
    end
  end
end
