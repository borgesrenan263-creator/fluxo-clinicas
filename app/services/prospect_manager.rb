class ProspectManager
  SIX_MONTHS_SECONDS = 60 * 60 * 24 * 30 * 6
  IGNORE_AFTER_SECONDS = 60 * 60 * 48

  def initialize(db)
    @db = db
  end

  def mark_contacted(prospect_id)
    now = Time.now

    @db[:prospects].where(id: prospect_id).update(
      status: "contatado",
      last_contacted_at: now,
      updated_at: now
    )

    add_event(prospect_id, "contatado", "Prospect marcado como contatado.")
  end

  def register_response(prospect_id, status, body)
    now = Time.now

    @db[:prospects].where(id: prospect_id).update(
      status: status,
      responded_at: now,
      notes: body,
      updated_at: now
    )

    add_event(prospect_id, status, body)
  end

  def promote_to_company(prospect_id)
    prospect = @db[:prospects].where(id: prospect_id).first
    return nil unless prospect

    now = Time.now

    company_id = @db[:companies].insert(
      name: prospect[:name],
      phone: best_phone(prospect),
      email: prospect[:email],
      plan_name: "prospeccao",
      payment_status: "pendente",
      prospect_id: prospect[:id],
      created_at: now,
      updated_at: now
    )

    @db[:prospects].where(id: prospect_id).update(
      status: "cliente_confirmado",
      confirmed_at: now,
      updated_at: now
    )

    add_event(prospect_id, "cliente_confirmado", "Prospect convertido em cliente.")

    company_id
  end

  def archive_ignored_after_48h
    now = Time.now
    archived = 0

    @db[:prospects].where(status: "contatado").all.each do |prospect|
      next unless prospect[:last_contacted_at]

      last_contacted = Time.parse(prospect[:last_contacted_at].to_s)
      next unless now - last_contacted >= IGNORE_AFTER_SECONDS

      @db[:prospects].where(id: prospect[:id]).update(
        status: "ignorado",
        archived_at: now,
        do_not_contact_until: now + SIX_MONTHS_SECONDS,
        updated_at: now
      )

      add_event(
        prospect[:id],
        "ignorado",
        "Prospect arquivado automaticamente após 48h sem retorno. Bloqueio de contato por 6 meses."
      )

      archived += 1
    end

    archived
  end

  def eligible_for_contact?(prospect)
    return true unless prospect[:do_not_contact_until]

    Time.parse(prospect[:do_not_contact_until].to_s) <= Time.now
  end

  private

  def best_phone(prospect)
    prospect[:whatsapp].to_s.strip.empty? ? prospect[:phone] : prospect[:whatsapp]
  end

  def add_event(prospect_id, event_type, body)
    @db[:prospect_events].insert(
      prospect_id: prospect_id,
      event_type: event_type,
      body: body,
      created_at: Time.now
    )
  end
end
