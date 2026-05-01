require "fileutils"

class CampaignPresetBuilder
  PRESETS = {
    "formal" => {
      label: "Campanha Formal Profissional",
      audience: "Pacientes que preferem uma comunicação objetiva, clara, educada e profissional.",
      tone: "Formal, respeitoso, direto e acolhedor.",
      best_for: "Clínicas tradicionais, tratamentos de maior valor e pacientes que precisam de segurança para retomar o contato.",
      templates: [
        {
          step: 1,
          title: "Primeiro contato",
          body: "Olá, [Nome]. Tudo bem? Estou entrando em contato porque você demonstrou interesse em [Procedimento]. Temos alguns horários disponíveis para avaliação nos próximos dias. Posso verificar uma opção adequada para você?",
          delay_hours: 0
        },
        {
          step: 2,
          title: "Lembrete respeitoso",
          body: "Olá, [Nome]. Passando apenas para lembrar que seguimos à disposição para ajudar com [Procedimento]. Se ainda fizer sentido para você, posso enviar algumas opções de horários disponíveis.",
          delay_hours: 24
        },
        {
          step: 3,
          title: "Encerramento educado",
          body: "Olá, [Nome]. Esta será minha última mensagem para não incomodar. Caso ainda tenha interesse em [Procedimento], será um prazer ajudar você com o agendamento.",
          delay_hours: 48
        }
      ]
    },

    "jovem_atual" => {
      label: "Campanha Atual para Jovens",
      audience: "Pacientes jovens, digitais e acostumados com mensagens rápidas, simples e naturais.",
      tone: "Leve, direto, atual e sem formalidade excessiva.",
      best_for: "Clínicas com comunicação moderna, procedimentos estéticos, avaliação inicial, clareamento e consultas rápidas.",
      templates: [
        {
          step: 1,
          title: "Primeiro contato leve",
          body: "Oi, [Nome]! Tudo bem? Vi que você tinha interesse em [Procedimento]. Temos alguns horários livres essa semana. Quer que eu te mande as opções?",
          delay_hours: 0
        },
        {
          step: 2,
          title: "Lembrete rápido",
          body: "Passando rapidinho, [Nome]. Ainda dá tempo de ver um horário para [Procedimento]. Quer que eu confira os melhores horários para você?",
          delay_hours: 24
        },
        {
          step: 3,
          title: "Último retorno leve",
          body: "Última mensagem para não te incomodar, [Nome]. Se ainda fizer sentido cuidar de [Procedimento], posso te ajudar a reservar um horário.",
          delay_hours: 48
        }
      ]
    },

    "extrovertido" => {
      label: "Campanha Atual Extrovertida",
      audience: "Pacientes que respondem melhor a uma comunicação simpática, humana e com energia positiva.",
      tone: "Próximo, animado, simpático e com emojis moderados.",
      best_for: "Clínicas com perfil mais descontraído, ações promocionais leves e públicos que já interagem bem pelo WhatsApp.",
      templates: [
        {
          step: 1,
          title: "Primeiro contato simpático",
          body: "Oii, [Nome]! Tudo certo? Seu interesse em [Procedimento] apareceu por aqui e temos horários disponíveis. Quer que eu veja uma opção boa para você?",
          delay_hours: 0
        },
        {
          step: 2,
          title: "Lembrete simpático",
          body: "[Nome], passando só para não deixar seu interesse em [Procedimento] cair no esquecimento. Quer que eu te mande os horários livres?",
          delay_hours: 24
        },
        {
          step: 3,
          title: "Última chamada simpática",
          body: "Prometo que é a última, [Nome]. Se ainda quiser resolver [Procedimento], posso separar um horário rápido para você.",
          delay_hours: 48
        }
      ]
    },

    "experiente_formal" => {
      label: "Campanha Formal para Público Experiente",
      audience: "Pessoas mais experientes, que valorizam respeito, paciência, clareza e atendimento cuidadoso.",
      tone: "Calmo, formal, educado, humano e acolhedor.",
      best_for: "Tratamentos que exigem confiança, pacientes mais conservadores, retorno de orçamento e avaliações odontológicas.",
      templates: [
        {
          step: 1,
          title: "Primeiro contato acolhedor",
          body: "Olá, [Nome]. Espero que esteja bem. Estamos entrando em contato porque você demonstrou interesse em [Procedimento]. Podemos verificar com calma um horário de avaliação para você?",
          delay_hours: 0
        },
        {
          step: 2,
          title: "Lembrete acolhedor",
          body: "Olá, [Nome]. Gostaria apenas de reforçar que seguimos à disposição para auxiliar você com [Procedimento]. Se desejar, posso informar os horários disponíveis.",
          delay_hours: 24
        },
        {
          step: 3,
          title: "Encerramento cuidadoso",
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
    return {
      created: 0,
      skipped: 0,
      label: "Preset não encontrado",
      doc_text: "",
      doc_file: nil
    } unless preset

    created = 0
    skipped = 0
    now = Time.now

    preset[:templates].each do |template|
      template_title = "#{preset[:label]} - #{template[:title]}"
      exists = @db[:message_templates].where(title: template_title).count > 0

      if exists
        skipped += 1
        next
      end

      @db[:message_templates].insert(
        step: template[:step],
        title: template_title,
        body: template[:body],
        delay_hours: template[:delay_hours],
        active: 1,
        created_at: now,
        updated_at: now
      )

      created += 1
    end

    doc_text = build_doc_text(preset)
    doc_file = save_doc_file(key, doc_text)

    {
      created: created,
      skipped: skipped,
      label: preset[:label],
      audience: preset[:audience],
      tone: preset[:tone],
      best_for: preset[:best_for],
      doc_text: doc_text,
      doc_file: doc_file
    }
  end

  private

  def build_doc_text(preset)
    lines = []

    lines << "CLÍNICAS PRO"
    lines << "Documento de Campanha de Reativação"
    lines << ""
    lines << "============================================================"
    lines << preset[:label].upcase
    lines << "============================================================"
    lines << ""
    lines << "1. OBJETIVO DA CAMPANHA"
    lines << ""
    lines << "Esta campanha foi criada para reativar pacientes que já demonstraram"
    lines << "interesse em um procedimento, avaliação ou atendimento, mas que ainda"
    lines << "não concluíram o agendamento."
    lines << ""
    lines << "A proposta é retomar o contato de forma ética, organizada e humana,"
    lines << "sem insistência excessiva e sempre respeitando a decisão do paciente."
    lines << ""
    lines << "2. PÚBLICO INDICADO"
    lines << ""
    lines << preset[:audience]
    lines << ""
    lines << "Melhor aplicação:"
    lines << preset[:best_for]
    lines << ""
    lines << "3. TOM DE COMUNICAÇÃO"
    lines << ""
    lines << preset[:tone]
    lines << ""
    lines << "A comunicação deve parecer uma conversa natural de atendimento,"
    lines << "sem pressão, sem promessas exageradas e sem linguagem robótica."
    lines << ""
    lines << "4. VARIÁVEIS USADAS NAS MENSAGENS"
    lines << ""
    lines << "[Nome]"
    lines << "Substituir pelo nome do paciente."
    lines << ""
    lines << "[Procedimento]"
    lines << "Substituir pelo procedimento ou interesse demonstrado."
    lines << ""
    lines << "Exemplo:"
    lines << "[Nome] = Maria"
    lines << "[Procedimento] = Clareamento"
    lines << ""
    lines << "5. SEQUÊNCIA RECOMENDADA"
    lines << ""
    lines << "Mensagem 1:"
    lines << "Enviar no primeiro contato de reativação."
    lines << ""
    lines << "Mensagem 2:"
    lines << "Enviar aproximadamente 24 horas depois, somente se não houver resposta."
    lines << ""
    lines << "Mensagem 3:"
    lines << "Enviar aproximadamente 48 horas depois, como última tentativa educada."
    lines << ""
    lines << "Se o paciente responder com interesse, interrompa a sequência automática"
    lines << "e encaminhe o atendimento para agendamento."
    lines << ""
    lines << "6. MENSAGENS DA CAMPANHA"
    lines << ""

    preset[:templates].each do |template|
      lines << "------------------------------------------------------------"
      lines << "MENSAGEM #{template[:step]} - #{template[:title].upcase}"
      lines << "Quando enviar: após #{template[:delay_hours]} hora(s)"
      lines << "------------------------------------------------------------"
      lines << ""
      lines << template[:body]
      lines << ""
    end

    lines << "7. COMO USAR NO ATENDIMENTO"
    lines << ""
    lines << "1. Selecione apenas contatos legítimos da própria clínica."
    lines << "2. Confira se o paciente já demonstrou interesse anteriormente."
    lines << "3. Substitua [Nome] e [Procedimento] antes do envio, se necessário."
    lines << "4. Envie a primeira mensagem pelo WhatsApp da clínica ou central."
    lines << "5. Registre no sistema se a mensagem foi enviada."
    lines << "6. Se houver resposta, classifique o contato corretamente."
    lines << "7. Se o paciente quiser agendar, marque como 'Quer agendar'."
    lines << "8. Se o paciente não quiser receber mensagens, marque como 'Não perturbar'."
    lines << ""
    lines << "8. CLASSIFICAÇÃO DE RESPOSTAS"
    lines << ""
    lines << "Interessado:"
    lines << "Paciente pediu mais informações ou demonstrou intenção de continuar."
    lines << ""
    lines << "Quer agendar:"
    lines << "Paciente pediu horário, data, disponibilidade ou confirmou intenção de marcar."
    lines << ""
    lines << "Sem interesse:"
    lines << "Paciente respondeu que não deseja seguir no momento."
    lines << ""
    lines << "Não perturbar:"
    lines << "Paciente pediu para não receber novas mensagens."
    lines << ""
    lines << "Convertido:"
    lines << "Paciente agendou, compareceu ou fechou o procedimento, conforme o controle da clínica."
    lines << ""
    lines << "9. BOAS PRÁTICAS"
    lines << ""
    lines << "- Use somente contatos autorizados ou legítimos da própria clínica."
    lines << "- Não compre listas de contatos."
    lines << "- Não envie mensagens em excesso."
    lines << "- Não prometa resultados clínicos, estéticos ou financeiros."
    lines << "- Não use linguagem de pressão ou urgência falsa."
    lines << "- Respeite pedidos de remoção ou interrupção de contato."
    lines << "- Mantenha o tom humano, educado e profissional."
    lines << ""
    lines << "10. OBSERVAÇÃO IMPORTANTE"
    lines << ""
    lines << "Este material é um guia operacional. A equipe deve adaptar a mensagem"
    lines << "ao contexto real do paciente, mantendo ética, clareza e respeito."
    lines << ""
    lines << "============================================================"
    lines << "Documento gerado pelo Clínicas Pro"
    lines << "============================================================"

    lines.join("\n")
  end

  def save_doc_file(key, doc_text)
    FileUtils.mkdir_p("storage/campaign_docs")

    timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
    file_path = "storage/campaign_docs/campanha_#{key}_#{timestamp}.txt"

    # BOM UTF-8 para abrir corretamente em Android, Windows e editores simples.
    bom = "\uFEFF"

    File.open(file_path, "w:UTF-8") do |file|
      file.write(bom)
      file.write(doc_text.encode("UTF-8", invalid: :replace, undef: :replace, replace: ""))
    end

    file_path
  end
end
