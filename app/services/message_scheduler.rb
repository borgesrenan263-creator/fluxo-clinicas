class MessageScheduler
  def initialize(db)
    @db = db
  end

  def schedule_for_all_contacts
    contacts = @db[:contacts].all
    templates = @db[:message_templates].where(active: 1).order(:step).all

    created = 0
    skipped = 0

    contacts.each do |contact|
      templates.each do |template|
        already_exists = @db[:messages].where(
          contact_id: contact[:id],
          template_id: template[:id]
        ).count > 0

        if already_exists
          skipped += 1
          next
        end

        body = template[:body].to_s
          .gsub("[Nome]", contact[:name].to_s)
          .gsub("[Procedimento]", contact[:procedure_name].to_s)

        scheduled_at = Time.now + (template[:delay_hours].to_i * 3600)

        @db[:messages].insert(
          contact_id: contact[:id],
          template_id: template[:id],
          body: body,
          status: "pendente",
          scheduled_at: scheduled_at,
          created_at: Time.now,
          updated_at: Time.now
        )

        created += 1
      end
    end

    {
      created: created,
      skipped: skipped
    }
  end
end
