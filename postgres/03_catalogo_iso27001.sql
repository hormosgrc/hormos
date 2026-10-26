-- Hormos — CATÁLOGO da ISO/IEC 27001:2022 (Anexo A)
--
-- Este arquivo é NORMA, não demonstração: os 93 controles do Anexo A, com
-- código, domínio e título. Toda instalação precisa dele, e ele não contém
-- decisão de empresa nenhuma.
--
-- O que ficou de FORA, e por quê: a aplicabilidade, a justificativa, o
-- responsável, a maturidade e o status de implantação são DECISÕES de uma
-- organização sobre o próprio SGSI. Até 26/10/2026 eles vinham junto, e uma
-- instalação nova nascia com a Declaração de Aplicabilidade preenchida por
-- uma empresa fictícia — indistinguível, na tela, do trabalho do próprio
-- cliente. Quem fosse auditado teria de provar de onde veio cada linha.
--
-- A demonstração mudou-se para `exemplos/demo.sql`, que NÃO roda sozinho.
-- A mesma distinção já existia no código: `app._SOA_CATALOGO` lista
-- exatamente as colunas que são catálogo, e é por ela que o modo auditor
-- copia o Anexo A para a base de um cliente novo sem levar junto o
-- julgamento de outro.

INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.1','controle','A.5','Organizacionais','Políticas de segurança da informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.2','controle','A.5','Organizacionais','Papéis e Responsabilidades pela segurança da informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.3','controle','A.5','Organizacionais','Segregação de funções') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.4','controle','A.5','Organizacionais','Responsabilidades da Direção') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.5','controle','A.5','Organizacionais','Contato com Autoridades') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.6','controle','A.5','Organizacionais','Contato com Grupo de Interesse Especial') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.7','controle','A.5','Organizacionais','Inteligência de Ameaças') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.8','controle','A.5','Organizacionais','Segurança da Informação no Gerenciamento de Projetos') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.9','controle','A.5','Organizacionais','Inventário de informações e outros ativos associados') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.10','controle','A.5','Organizacionais','Uso Aceitável de Informações e Outros Ativos Associados') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.11','controle','A.5','Organizacionais','Devolução de Ativos') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.12','controle','A.5','Organizacionais','Classsificação dass Informações') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.13','controle','A.5','Organizacionais','Rotulagem de Informações') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.14','controle','A.5','Organizacionais','Transferência de Informações') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.15','controle','A.5','Organizacionais','Controle de Acesso') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.16','controle','A.5','Organizacionais','Gestão de Identidade') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.17','controle','A.5','Organizacionais','Informações de Autenticação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.18','controle','A.5','Organizacionais','Direitos de Acesso') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.19','controle','A.5','Organizacionais','Segurança da Informação nas Relações com Fornecedores') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.20','controle','A.5','Organizacionais','Abordagem da Segurança da Informaçãonos nos Fornecedores') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.21','controle','A.5','Organizacionais','Gestão da Segurança da Informação na Cadeia de Fornecimento de Tecnologia de Informação e Comunicação (TIC)') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.22','controle','A.5','Organizacionais','Monitoramento, Análise Crítica e Gestão de Mudanças dos Serviços de Fornecedores') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.23','controle','A.5','Organizacionais','Segurança da Informação para Uso de Serviços em Nuvem') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.24','controle','A.5','Organizacionais','Planejamento e Preparação de Gestão de Incidentes da Segurança da Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.25','controle','A.5','Organizacionais','Avaliação e Decisão Sobre Eventos da Segurança da Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.26','controle','A.5','Organizacionais','Resposta a Incidentes da Segurança da Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.27','controle','A.5','Organizacionais','Aprendizado com Incidentes de Segurança da Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.28','controle','A.5','Organizacionais','Coleta de Evidências') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.29','controle','A.5','Organizacionais','Segurança da Informação Durante a Disrupção') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.30','controle','A.5','Organizacionais','Prontidão de TIC para Continuidade de Negócios') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.31','controle','A.5','Organizacionais','Requisitos Legais, Estatutários, Regulamentares e Contratuais') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.32','controle','A.5','Organizacionais','Direitos de Propriedade Intelectual') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.33','controle','A.5','Organizacionais','Proteção de Registros') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.34','controle','A.5','Organizacionais','Privacidade e Proteção de Dados Pessoais') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.35','controle','A.5','Organizacionais','Análise Crítica Independente da Segurança da Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.36','controle','A.5','Organizacionais','Compliance com as Políticas, Regras e Normas para Segurança da Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.5.37','controle','A.5','Organizacionais','Documentação dos Procedimentos de Operação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.6.1','controle','A.6','Pessoas','Seleção') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.6.2','controle','A.6','Pessoas','Termos e Condições de Contratação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.6.3','controle','A.6','Pessoas','Conscientização, Educação e Treinamento em Segurança da Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.6.4','controle','A.6','Pessoas','Processo Disciplinar') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.6.5','controle','A.6','Pessoas','Responsabilidades após Encerramento ou Mudanças da Contratação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.6.6','controle','A.6','Pessoas','Acordos de Confidencialidade ou Não Divulgação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.6.7','controle','A.6','Pessoas','Trabalho Remoto') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.6.8','controle','A.6','Pessoas','Relato de Eventos de Segurança da Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.1','controle','A.7','Físicos','Perímetro de segurança física') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.2','controle','A.7','Físicos','Entrada Física') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.3','controle','A.7','Físicos','Segurança de Escritórios, Salas e Instalações') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.4','controle','A.7','Físicos','Monitoramento de Segurança Física') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.5','controle','A.7','Físicos','Proteção Contra Ameaças Físicas e Ambientais') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.6','controle','A.7','Físicos','Trabalho em Áreas Seguras') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.7','controle','A.7','Físicos','Mesa Limpa e Tela Limpa') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.8','controle','A.7','Físicos','Locação e Proteção de Equipamentos') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.9','controle','A.7','Físicos','Segurança de Ativos Fora das Instalações da Organização') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.10','controle','A.7','Físicos','Mídias de Armazenamentos') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.11','controle','A.7','Físicos','Serviços de Infraestrutura') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.12','controle','A.7','Físicos','Segurança do Cabeamento') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.13','controle','A.7','Físicos','Manutenção de Equipamentos') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.7.14','controle','A.7','Físicos','Descarte Seguro ou Reutilização de Equipamentos') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.1','controle','A.8','Tecnológicos','Dispositivos Endpoint do Usuário') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.2','controle','A.8','Tecnológicos','Direitos de Acesso Privilegiados') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.3','controle','A.8','Tecnológicos','Restrição de Acesso à Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.4','controle','A.8','Tecnológicos','Acesso ao Código Fonte') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.5','controle','A.8','Tecnológicos','Autenticação Segura') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.6','controle','A.8','Tecnológicos','Gestão de Capacidade') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.7','controle','A.8','Tecnológicos','Proteção Contra Malware') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.8','controle','A.8','Tecnológicos','Gestão de Vulnerabilidade Técnicas Gestão de Configuração') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.9','controle','A.8','Tecnológicos','Gestão de Configuração') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.10','controle','A.8','Tecnológicos','Exclusão de Informação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.11','controle','A.8','Tecnológicos','Mascaramento de Dados') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.12','controle','A.8','Tecnológicos','Prevenção de Vazamentos de Dados') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.13','controle','A.8','Tecnológicos','Backup das Informações') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.14','controle','A.8','Tecnológicos','Redudância dos Recursos de Processamento de Informações') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.15','controle','A.8','Tecnológicos','Log') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.16','controle','A.8','Tecnológicos','Atividades de Monitoramento') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.17','controle','A.8','Tecnológicos','Sincronização do Relógio') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.18','controle','A.8','Tecnológicos','Uso de Programa Utilitários Privilegiados') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.19','controle','A.8','Tecnológicos','Instalação de Softwares em Sistemas Operacionais') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.20','controle','A.8','Tecnológicos','Segurança de Redes') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.21','controle','A.8','Tecnológicos','Segurança dos Serviços de Rede') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.22','controle','A.8','Tecnológicos','Segregação de Redes') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.23','controle','A.8','Tecnológicos','Filtragem da Web') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.24','controle','A.8','Tecnológicos','Uso de Criptografia') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.25','controle','A.8','Tecnológicos','Ciclo de Vida de Desenvolvimento Seguro') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.26','controle','A.8','Tecnológicos','Requisitos de Segurança da Aplicação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.27','controle','A.8','Tecnológicos','Princípios de Arquitetura e Engenharia de Sistemas Seguro') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.28','controle','A.8','Tecnológicos','Codificação Segura') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.29','controle','A.8','Tecnológicos','Testes de Segurança em Desenvolvimento e Aceitação') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.30','controle','A.8','Tecnológicos','Desenvolvimento Terceirizado') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.31','controle','A.8','Tecnológicos','Separação dos Ambientes de Desenvolvimento, Testes e Produção') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.32','controle','A.8','Tecnológicos','Gestão de Mudanças') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.33','controle','A.8','Tecnológicos','Informações de Testes') ON CONFLICT (codigo) DO NOTHING;
INSERT INTO soa (codigo,categoria,dominio,dominio_label,titulo) VALUES ('A.8.34','controle','A.8','Tecnológicos','Proteção de Sistemas de Informação Durante os Testes de Auditoria') ON CONFLICT (codigo) DO NOTHING;

-- ========================================================================
-- Copiar controles SOA (ISO 27001) para fw_controles
-- Permite que o framework engine e mapeamentos cruzados incluam ISO 27001
-- ========================================================================
INSERT INTO fw_controles(framework_codigo, codigo, dominio, subdominio, titulo, ordem)
SELECT 'iso27001', codigo, dominio,
       CASE WHEN dominio='A.5' THEN 'Organizacionais'
            WHEN dominio='A.6' THEN 'Pessoas'
            WHEN dominio='A.7' THEN 'Físicos'
            ELSE 'Tecnológicos' END,
       titulo,
       ROW_NUMBER() OVER (ORDER BY codigo)
FROM soa
ON CONFLICT (framework_codigo, codigo) DO NOTHING;

-- Re-resolver mapeamentos agora que ISO 27001 está em fw_controles
CREATE TABLE IF NOT EXISTS fw_mapeamentos_seed_iso(
  origem_codigo TEXT, dest_fw TEXT, dest_codigo TEXT, relacao TEXT, notas TEXT
);
INSERT INTO fw_mapeamentos_seed_iso VALUES
  ('A.5.1',  'nist_csf','GV.PO-01',  'Equivalente',  'Políticas de SI ↔ função Policies NIST CSF'),
  ('A.5.15', 'nist_csf','PR.AA-05',  'Equivalente',  'Controle de acesso ↔ menor privilégio NIST'),
  ('A.5.23', 'nist_csf','GV.SC-03',  'Parcial',      'Segurança em nuvem ↔ risco de fornecedores NIST'),
  ('A.8.8',  'nist_csf','ID.RA-01',  'Equivalente',  'Gestão de vulnerabilidades ↔ avaliação NIST'),
  ('A.8.15', 'nist_csf','DE.CM-03',  'Equivalente',  'Logs de auditoria ↔ monitoramento contínuo NIST'),
  ('A.5.26', 'nist_csf','RS.MA-01',  'Equivalente',  'Resposta a incidentes ISO ↔ NIST'),
  ('A.8.13', 'nist_csf','PR.IR-03',  'Equivalente',  'Backup ISO ↔ resiliência NIST'),
  ('A.5.15', 'cis_v8',  'CIS.6.1',   'Equivalente',  'Controle de acesso ISO ↔ concessão de acesso CIS'),
  ('A.5.15', 'cis_v8',  'CIS.5.4',   'Complementar', 'Controle de acesso ↔ contas admin CIS'),
  ('A.8.8',  'cis_v8',  'CIS.7.1',   'Equivalente',  'Vulnerabilidades ISO ↔ CIS Control 7'),
  ('A.8.15', 'cis_v8',  'CIS.8.1',   'Equivalente',  'Logs ISO ↔ CIS Control 8'),
  ('A.5.26', 'cis_v8',  'CIS.17.4',  'Equivalente',  'Resposta a incidentes ISO ↔ CIS 17'),
  ('A.8.13', 'cis_v8',  'CIS.11.1',  'Equivalente',  'Backup ISO ↔ CIS Control 11'),
  ('A.7.2',  'cis_v8',  'CIS.14.1',  'Equivalente',  'Treinamento ISO ↔ CIS Control 14');

DO $$
DECLARE s RECORD; oid INT; did INT;
BEGIN
  FOR s IN SELECT * FROM fw_mapeamentos_seed_iso LOOP
    SELECT id INTO oid FROM fw_controles WHERE codigo=s.origem_codigo AND framework_codigo='iso27001' LIMIT 1;
    SELECT id INTO did FROM fw_controles WHERE codigo=s.dest_codigo   AND framework_codigo=s.dest_fw   LIMIT 1;
    IF oid IS NOT NULL AND did IS NOT NULL THEN
      INSERT INTO fw_mapeamentos(controle_origem_id,controle_destino_id,relacao,notas)
        VALUES(oid,did,s.relacao,s.notas) ON CONFLICT DO NOTHING;
    END IF;
  END LOOP;
END $$;
DROP TABLE IF EXISTS fw_mapeamentos_seed_iso;

-- Atualizar total_controles para iso27001 com valor real
UPDATE frameworks SET total_controles=(SELECT count(*) FROM fw_controles WHERE framework_codigo='iso27001') WHERE codigo='iso27001';

