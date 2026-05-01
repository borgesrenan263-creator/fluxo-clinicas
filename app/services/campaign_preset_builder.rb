class CampaignPresetBuilder
  PRESETS = {
    "formal" => {
      label: "Formal profissional",
      templates: [
        {
          step: 1,
          title: "Formal - Primeiro contato",
          body: "Olá, [Nome]. Tudo bem? Identificamos que você demonstrou interesse em [Procedimento]. Temos disponibilidade para avaliação nos próximos dias. Posso verificar um horário adequado para você?",
          delay_hours: 0
        },
        {
          step: 2,
          title: "Formal - Lembrete",
          body: "Olá, [Nome]. Passando para lembrar que ainda podemos auxiliar você com [Procedimento]. Caso faça sentido, posso enviar algumas opções de horários disponíveis.",
          delay_hours: 24
        },
        {
          step: 3,
          title: "Formal - Último retorno",
          body: "Olá, [Nome]. Esta é apenas uma última mensagem para não incomodar. Se ainda houver interesse em [Procedimento], fico à disposição para ajudar com o agendamento.",
          delay_hours: 48
        }
      ]
    },

    "jovem_atual" => {
      label: "Atual para jovens",
      templates: [
        {
          step: 1,
          title: "Jovem atual - Primeiro contato",
          body: "Oi, [Nome]! Tudo bem? Vi que você tinha interesse em [Procedimento]. Temos alguns horários livres essa semana. Quer que eu te mande as opções?",
          delay_hours: 0
        },
        {
          step: 2,
          title: "Jovem atual - Lembrete",
          body: "Passando rapidinho, [Nome] 😊 Ainda dá tempo de ver um horário para [Procedimento]. Quer que eu confira os melhores horários pra você?",
          delay_hours: 24
        },
        {
          step: 3,
          title: "Jovem atual - Última tentativa",
          body: "Última mensagem para não te incomodar, [Nome]. Se ainda fizer sentido cuidar de [Procedimento], posso te ajudar a reservar um horário.",
          delay_hours: 48
        }
      ]
    },

    "extrovertido" => {
      label: "Atual e extrovertido",
      templates: [
        {
          step: 1,
          title: "Extrovertido - Primeiro contato",
          body: "Oii, [Nome]! 😄 Tudo certo? Seu interesse em [Procedimento] apareceu por aqui e temos horários disponíveis. Bora ver uma opção boa pra você?",
          delay_hours: 0
        },
        {
          step: 2,
          title: "Extrovertido - Lembrete",
          body: "[Nome], passando só para não deixar seu [Procedimento] cair no esquecimento 😅 Quer que eu te mande os horários livres?",
          delay_hours: 24
        },
        {
          step: 3,
          title: "Extrovertido - Última chamada",
          body: "Prometo que é a última, [Nome] 😄 Se ainda quiser resolver [Procedimento], posso separar um horário rápido para você.",
          delay_hours: 48
        }
      ]
    },

    "experiente_formal" => {
      label: "Formal para público experiente",
      templates: [
        {
          step: 1,
          title: "Experiente formal - Primeiro contato",
          body: "Olá, [Nome]. Espero que esteja bem. Estamos entrando em contato porque você demonstrou interesse em [Procedimento]. Podemos verificar com calma um horário de avaliação para você?",
          delay_hours: 0
        },
        {
          step: 2,
          title: "Experiente formal - Lembrete",
          body: "Olá, [Nome]. Gostaria apenas de reforçar que seguimos à disposição para auxiliar com [Procedimento]. Se desejar, posso informar os horários disponíveis.",
          delay_hours: 24
        },
        {
          step: 3,
          title: "Experiente formal - Encerramento",
          body: "Olá, [Nome]. Para não incomodar, esta será nossa última mensagem. Caso ainda tenha interesse em [Procedimento], será um prazer ajudar no agendamento.",
          delay_hours: 48
        }
      ]
    }
  }

  def initialize(db)
    @db = db
  end

  def create_preset(key)
    preset = PRESETS[key]
    return { created: 0, skipped: 0, label: "Preset não encontrado" } unless preset

    created = 0
    skipped = 0
    now = Time.now

    preset[:templates].each do |template|
      exists = @db[:message_templates].where(title: template[:title]).count > 0

      if exists
        skipped += 1
        next
      end

      @db[:message_templates].insert(
        step: template[:step],
        title: template[:title],
        body: template[:body],
        delay_hours: template[:delay_hours],
        active: 1,
        created_at: now,
        updated_at: now
      )

      created += 1
    end

    {
      created: created,
      skipped: skipped,
      label: preset[:label]
    }
  end
end
