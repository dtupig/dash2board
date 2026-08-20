/**
 * Seed reproduzível do tenant de demonstração.
 *
 * Gera EXATAMENTE os mesmos dados de `MockStrategicRepository`
 * (lib/features/strategic/data/mock_strategic_repository.dart), para que o
 * modo mock e o modo Firestore real sejam comparáveis lado a lado - mesma
 * âncora (2026-08-01), mesmo índice de postura (72, mediana 68), mesmos seis
 * domínios, os mesmos 24 controles de compliance, os mesmos 6 riscos, os
 * mesmos 8 insights e a mesma pesquisa ativa.
 *
 * Uso:
 *   npm run seed        -> emulador local (FIRESTORE_EMULATOR_HOST / FIREBASE_AUTH_EMULATOR_HOST)
 *   npm run seed:prod   -> projeto real; exige CONFIRM_PROD=1 e --project=<id>
 *
 * Idempotente: toda escrita usa um id determinístico e `.set()` (nunca
 * `.add()`), então rodar duas vezes produz o mesmo estado, não duplica nada.
 */

import * as admin from "firebase-admin";
import * as fs from "fs";
import * as path from "path";

// ---------------------------------------------------------------------------
// 0. Modo de execução
// ---------------------------------------------------------------------------

const isProd = process.argv.includes("--prod");

if (isProd) {
  if (process.env.CONFIRM_PROD !== "1") {
    console.error(
      "[seed] Recusando rodar contra um projeto real sem CONFIRM_PROD=1.\n" +
        "       Isso existe para que seedar produção seja uma decisão " +
        "deliberada, nunca um acidente de terminal."
    );
    process.exit(1);
  }
  const projectArg = process.argv.find((arg) => arg.startsWith("--project="));
  if (!projectArg) {
    console.error(
      "[seed] --project=<id> é obrigatório em modo --prod (não assumimos " +
        "qual projeto real você quer seedar)."
    );
    process.exit(1);
  }
} else {
  // Emulador por padrão - só define se o ambiente não tiver sobrescrito.
  process.env.FIRESTORE_EMULATOR_HOST ??= "localhost:8080";
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= "localhost:9099";
}

function readProjectId(): string {
  const projectArg = process.argv.find((arg) => arg.startsWith("--project="));
  if (projectArg) {
    return projectArg.split("=")[1];
  }
  // Modo emulador: usa o projeto "default" declarado em .firebaserc, para
  // não exigir uma flag extra no dia a dia. `.firebaserc` não tem extensão
  // .json, então require() tenta compilar como JS - lemos e parseamos à mão.
  const rcPath = path.join(__dirname, "..", "..", "..", ".firebaserc");
  const rc = JSON.parse(fs.readFileSync(rcPath, "utf8"));
  const defaultProjectId = rc.projects?.default;
  if (!defaultProjectId) {
    throw new Error(
      "[seed] .firebaserc não declara projects.default. Rode " +
        "`firebase use --add` ou passe --project=<id>."
    );
  }
  return defaultProjectId;
}

const projectId = readProjectId();
admin.initializeApp({projectId});

const auth = admin.auth();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// 1. Constantes espelhando MockStrategicRepository
// ---------------------------------------------------------------------------

const TENANT_ID = "tenant-demo";
const ANCHOR = new Date(Date.UTC(2026, 7, 1)); // 2026-08-01, mês 0-indexado em JS

function monthsBefore(from: Date, months: number): Date {
  return new Date(Date.UTC(from.getUTCFullYear(), from.getUTCMonth() - months, from.getUTCDate()));
}

function daysBefore(from: Date, days: number): Date {
  return new Date(from.getTime() - days * 86_400_000);
}

function daysAfter(from: Date, days: number): Date {
  return new Date(from.getTime() + days * 86_400_000);
}

const MONTHLY_OVERALL_SCORES = [64, 65, 66, 67, 68, 69, 66, 65, 68, 70, 71, 72];
const PEER_MEDIAN = 68;

const BY_DOMAIN_TODAY: Record<string, number> = {
  identity: 81,
  endpoint: 76,
  cloud: 63,
  appsec: 58,
  data: 74,
  thirdparty: 55,
};

// Variação de cada domínio nos últimos 30 dias - espelha
// `_byDomainDelta30d` do MockStrategicRepository. Appsec e terceiros
// pioraram no mês mesmo com a média geral melhorando.
const BY_DOMAIN_DELTA_30D: Record<string, number> = {
  identity: 2,
  endpoint: 1,
  cloud: 3,
  appsec: -2,
  data: 1,
  thirdparty: -1,
};

interface ComplianceSeed {
  framework: string;
  controlId: string;
  title: string;
  status: "compliant" | "partial" | "gap";
  ownerName: string;
  reviewedDaysAgo: number;
  domain: string;
}

function evidenceFor(controlId: string, status: string): string | null {
  return status === "gap"
    ? null
    : `https://evidencias.elytronsecurity.com/${TENANT_ID}/${controlId}`;
}

const COMPLIANCE_CONTROLS: ComplianceSeed[] = [
  // ISO 27001
  {framework: "ISO27001", controlId: "A.5.1", title: "Políticas de segurança da informação", status: "compliant", ownerName: "Mariana Costa", reviewedDaysAgo: 20, domain: "data"},
  {framework: "ISO27001", controlId: "A.8.1", title: "Inventário de ativos de informação", status: "compliant", ownerName: "Eduardo Lima", reviewedDaysAgo: 35, domain: "endpoint"},
  {framework: "ISO27001", controlId: "A.9.2", title: "Gestão de acesso de usuários", status: "partial", ownerName: "Patrícia Alves", reviewedDaysAgo: 50, domain: "identity"},
  {framework: "ISO27001", controlId: "A.12.6", title: "Gestão de vulnerabilidades técnicas", status: "gap", ownerName: "Fernando Rocha", reviewedDaysAgo: 65, domain: "appsec"},
  {framework: "ISO27001", controlId: "A.16.1", title: "Gestão de incidentes de segurança da informação", status: "compliant", ownerName: "Juliana Prado", reviewedDaysAgo: 15, domain: "endpoint"},
  {framework: "ISO27001", controlId: "A.5.23", title: "Segurança da informação para uso de serviços em nuvem", status: "partial", ownerName: "Rodrigo Teixeira", reviewedDaysAgo: 80, domain: "cloud"},
  // NIST CSF
  {framework: "NIST_CSF", controlId: "ID.AM-2", title: "Inventário de plataformas e aplicações de software", status: "compliant", ownerName: "Eduardo Lima", reviewedDaysAgo: 28, domain: "endpoint"},
  {framework: "NIST_CSF", controlId: "PR.AC-1", title: "Identidades e credenciais gerenciadas para usuários", status: "compliant", ownerName: "Mariana Costa", reviewedDaysAgo: 22, domain: "identity"},
  {framework: "NIST_CSF", controlId: "PR.DS-5", title: "Proteção contra vazamento de dados", status: "partial", ownerName: "Patrícia Alves", reviewedDaysAgo: 44, domain: "data"},
  {framework: "NIST_CSF", controlId: "DE.CM-8", title: "Varredura contínua de vulnerabilidades", status: "gap", ownerName: "Fernando Rocha", reviewedDaysAgo: 70, domain: "appsec"},
  {framework: "NIST_CSF", controlId: "RS.RP-1", title: "Plano de resposta a incidentes executado", status: "compliant", ownerName: "Juliana Prado", reviewedDaysAgo: 18, domain: "endpoint"},
  {framework: "NIST_CSF", controlId: "ID.SC-4", title: "Fornecedores monitorados quanto ao risco introduzido", status: "gap", ownerName: "Rodrigo Teixeira", reviewedDaysAgo: 90, domain: "thirdparty"},
  // LGPD
  {framework: "LGPD", controlId: "Art.6", title: "Princípios do tratamento de dados pessoais observados", status: "compliant", ownerName: "Patrícia Alves", reviewedDaysAgo: 30, domain: "data"},
  {framework: "LGPD", controlId: "Art.46", title: "Medidas de segurança técnicas e administrativas", status: "compliant", ownerName: "Mariana Costa", reviewedDaysAgo: 25, domain: "data"},
  {framework: "LGPD", controlId: "Art.48", title: "Comunicação de incidente de segurança à ANPD", status: "partial", ownerName: "Fernando Rocha", reviewedDaysAgo: 55, domain: "endpoint"},
  {framework: "LGPD", controlId: "Art.37", title: "Registro das operações de tratamento de dados", status: "compliant", ownerName: "Juliana Prado", reviewedDaysAgo: 40, domain: "data"},
  {framework: "LGPD", controlId: "Art.41", title: "Encarregado de proteção de dados (DPO) formalizado", status: "compliant", ownerName: "Eduardo Lima", reviewedDaysAgo: 60, domain: "data"},
  {framework: "LGPD", controlId: "Art.39", title: "Contratos com operadores de dados revisados", status: "partial", ownerName: "Rodrigo Teixeira", reviewedDaysAgo: 75, domain: "thirdparty"},
  // PCI DSS
  {framework: "PCI_DSS", controlId: "Req.1", title: "Firewall e segmentação de rede", status: "compliant", ownerName: "Fernando Rocha", reviewedDaysAgo: 33, domain: "cloud"},
  {framework: "PCI_DSS", controlId: "Req.3", title: "Proteção de dados de titulares de cartão armazenados", status: "compliant", ownerName: "Mariana Costa", reviewedDaysAgo: 27, domain: "data"},
  {framework: "PCI_DSS", controlId: "Req.6", title: "Desenvolvimento seguro de aplicações", status: "gap", ownerName: "Patrícia Alves", reviewedDaysAgo: 85, domain: "appsec"},
  {framework: "PCI_DSS", controlId: "Req.8", title: "Identificação e autenticação de acesso", status: "compliant", ownerName: "Juliana Prado", reviewedDaysAgo: 19, domain: "identity"},
  {framework: "PCI_DSS", controlId: "Req.10", title: "Rastreamento e monitoramento de todos os acessos", status: "partial", ownerName: "Eduardo Lima", reviewedDaysAgo: 48, domain: "identity"},
  {framework: "PCI_DSS", controlId: "Req.12", title: "Avaliação de risco de fornecedores terceirizados", status: "gap", ownerName: "Rodrigo Teixeira", reviewedDaysAgo: 95, domain: "thirdparty"},
];

interface RiskSeed {
  id: string;
  title: string;
  businessUnit: string;
  domain: string;
  inherentScore: number;
  residualScore: number;
  annualLossExpectancy: number;
  currency: string;
  treatment: string;
  acceptance: string;
  reviewDueInDays: number;
}

const RISKS: RiskSeed[] = [
  {id: "risk-thirdparty-payments", title: "Vazamento de dados de clientes por falha de segurança em processador de pagamentos terceirizado", businessUnit: "Varejo", domain: "thirdparty", inherentScore: 82, residualScore: 55, annualLossExpectancy: 4_200_000, currency: "BRL", treatment: "mitigate", acceptance: "pending", reviewDueInDays: 30},
  {id: "risk-ecommerce-ddos", title: "Indisponibilidade do e-commerce por ataque de negação de serviço", businessUnit: "Varejo", domain: "cloud", inherentScore: 70, residualScore: 40, annualLossExpectancy: 1_800_000, currency: "BRL", treatment: "mitigate", acceptance: "accepted", reviewDueInDays: 90},
  {id: "risk-ot-segmentation", title: "Falha de segregação de acesso entre sistemas corporativos e de manufatura (OT/IT)", businessUnit: "Indústria", domain: "endpoint", inherentScore: 75, residualScore: 50, annualLossExpectancy: 2_600_000, currency: "BRL", treatment: "mitigate", acceptance: "pending", reviewDueInDays: 45},
  {id: "risk-ip-exposure", title: "Exposição de propriedade intelectual industrial por aplicação vulnerável", businessUnit: "Indústria", domain: "appsec", inherentScore: 68, residualScore: 48, annualLossExpectancy: 950_000, currency: "BRL", treatment: "mitigate", acceptance: "pending", reviewDueInDays: 60},
  {id: "risk-transaction-fraud", title: "Fraude em transações digitais por falha de autenticação", businessUnit: "Serviços Financeiros", domain: "identity", inherentScore: 60, residualScore: 30, annualLossExpectancy: 3_100_000, currency: "BRL", treatment: "transfer", acceptance: "accepted", reviewDueInDays: 120},
  {id: "risk-regulatory-delay", title: "Não conformidade regulatória por atraso na resposta a um ataque cibernético", businessUnit: "Corporativo", domain: "data", inherentScore: 45, residualScore: 25, annualLossExpectancy: 180_000, currency: "BRL", treatment: "accept", acceptance: "accepted", reviewDueInDays: 180},
];

interface InsightSeed {
  id: string;
  topic: string;
  title: string;
  summary: string;
  publishedDaysAgo: number;
  isBenchmark: boolean;
}

const INSIGHTS: InsightSeed[] = [
  {id: "ransomware-varejo-2026", topic: "Ameaças", title: "Aumento de 35% em ataques de ransomware contra o varejo brasileiro", summary: "Grupos de ransomware miram cadeias de suprimento do varejo com dupla extorsão.", publishedDaysAgo: 5, isBenchmark: true},
  {id: "orcamento-ciso-2026", topic: "Estratégia", title: "Como CISOs de médio porte estão priorizando orçamento em 2026", summary: "Pesquisa com 200 CISOs mostra prioridade para identidade e segurança de aplicações.", publishedDaysAgo: 10, isBenchmark: true},
  {id: "benchmark-resposta-incidentes", topic: "Benchmark", title: "Benchmark setorial: maturidade de resposta a incidentes", summary: "Comparativo de MTTA e MTTR entre empresas do mesmo porte e segmento.", publishedDaysAgo: 15, isBenchmark: true},
  {id: "anpd-notificacao", topic: "Regulatório", title: "Nova resolução da ANPD sobre notificação de incidentes", summary: "Prazo e formato de comunicação de incidentes de segurança à autoridade nacional.", publishedDaysAgo: 20, isBenchmark: false},
  {id: "checklist-pci-dss-4", topic: "Compliance", title: "Checklist: preparando o comitê para a auditoria de PCI DSS 4.0", summary: "Os requisitos que mais geram lacuna nas auditorias do último ano.", publishedDaysAgo: 25, isBenchmark: false},
  {id: "terceiros-notificacao-tardia", topic: "Terceiros", title: "Pesquisa Elytron: 60% dos incidentes em fornecedores não são notificados a tempo", summary: "Levantamento aponta lacunas em cláusulas contratuais de notificação de incidente.", publishedDaysAgo: 30, isBenchmark: false},
  {id: "appsec-shift-left", topic: "AppSec", title: "Tendência: adoção de segurança de aplicações (AppSec) shift-left", summary: "Empresas que testam segurança no pipeline reduzem o custo de correção em até 6x.", publishedDaysAgo: 35, isBenchmark: false},
  {id: "panorama-ot-2026", topic: "Ameaças", title: "Panorama de ameaças para o setor industrial (OT) em 2026", summary: "Convergência OT/IT amplia a superfície de ataque em plantas industriais.", publishedDaysAgo: 40, isBenchmark: false},
];

const ACTIVE_SURVEY_ID = "seguranca-2027-prioridades";

const DEMO_ACCOUNTS: Array<{email: string; role: "operational" | "strategic" | "board"}> = [
  {email: "operacao@demo.elytron", role: "operational"},
  {email: "ciso@demo.elytron", role: "strategic"},
  {email: "board@demo.elytron", role: "board"},
];

// ---------------------------------------------------------------------------
// 2. Auth: contas de demonstração + convites + membros
// ---------------------------------------------------------------------------

function demoPassword(): string {
  const fromEnv = process.env.SEED_DEMO_PASSWORD;
  if (fromEnv) {
    return fromEnv;
  }
  if (!isProd) {
    // Só um valor previsível quando é claramente o emulador local - nunca em
    // modo --prod, onde SEED_DEMO_PASSWORD é obrigatório (ver checagem
    // abaixo).
    return "DemoElytron2026!";
  }
  console.error(
    "[seed] SEED_DEMO_PASSWORD é obrigatório em modo --prod - não " +
      "escrevemos uma senha previsível em um projeto real."
  );
  process.exit(1);
}

async function ensureAuthUser(email: string): Promise<string> {
  try {
    const existing = await auth.getUserByEmail(email);
    return existing.uid;
  } catch (error) {
    if ((error as {code?: string}).code !== "auth/user-not-found") {
      throw error;
    }
    const created = await auth.createUser({
      email,
      password: demoPassword(),
      emailVerified: true,
      displayName: email.split("@")[0],
    });
    return created.uid;
  }
}

/** Aplica os claims direto pelo Admin SDK, avisando que fez isso. */
async function applyClaimsDirectly(uid: string, role: string): Promise<void> {
  await auth.setCustomUserClaims(uid, {
    role,
    tenantId: TENANT_ID,
    tenantAdmin: false,
  });
  await auth.revokeRefreshTokens(uid);
  console.warn(
    `[seed] Functions emulator não detectado (ou não sincronizou a tempo) - ` +
      `claims de ${uid} aplicados direto pelo Admin SDK.`
  );
}

/**
 * Espera a Cloud Function `syncMemberClaims` (rodando no emulador de
 * Functions) sincronizar os claims a partir do documento de membro. Se não
 * sincronizar dentro do prazo, aplica direto e avisa (regra B do prompt).
 */
async function ensureClaims(uid: string, role: string): Promise<void> {
  const attempts = 6;
  const delayMs = 500;
  for (let attempt = 0; attempt < attempts; attempt++) {
    const user = await auth.getUser(uid);
    const claims = user.customClaims ?? {};
    if (claims.role === role && claims.tenantId === TENANT_ID) {
      return;
    }
    await new Promise((resolve) => setTimeout(resolve, delayMs));
  }
  await applyClaimsDirectly(uid, role);
}

async function seedAuthAndMembers(): Promise<Map<string, string>> {
  const uidByRole = new Map<string, string>();

  for (const account of DEMO_ACCOUNTS) {
    const uid = await ensureAuthUser(account.email);
    uidByRole.set(account.role, uid);

    await db.doc(`invites/${account.email}`).set({
      tenantId: TENANT_ID,
      role: account.role,
      tenantAdmin: false,
      displayName: account.email.split("@")[0],
      consumedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await db.doc(`tenants/${TENANT_ID}/members/${uid}`).set({
      uid,
      email: account.email,
      role: account.role,
      tenantId: TENANT_ID,
      tenantAdmin: false,
      displayName: account.email.split("@")[0],
      status: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await ensureClaims(uid, account.role);
    console.log(`[seed] ${account.email} -> uid ${uid}, papel ${account.role}`);
  }

  return uidByRole;
}

// ---------------------------------------------------------------------------
// 3. Dados estratégicos (espelham MockStrategicRepository)
// ---------------------------------------------------------------------------

async function seedTenantDoc(): Promise<void> {
  await db.doc(`tenants/${TENANT_ID}`).set({
    name: "Tenant Demo",
    // Espelham as mesmas constantes de MockStrategicRepository - usadas
    // pelo painel do board (exposição como % da receita, dono por unidade
    // de negócio, variação trimestral).
    annualRevenue: 180_000_000,
    businessUnitOwners: {
      "Varejo": "Camila Duarte, VP de Varejo",
      "Indústria": "Marcelo Andrade, VP de Indústria",
      "Serviços Financeiros": "Beatriz Nogueira, VP de Serviços Financeiros",
      "Corporativo": "Rafael Souza, CFO",
    },
    previousQuarterAle: 14_200_000,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function seedPostureIndex(): Promise<void> {
  const previousMonthScore = MONTHLY_OVERALL_SCORES[MONTHLY_OVERALL_SCORES.length - 2];
  await db.doc(`tenants/${TENANT_ID}/metrics/posture_index`).set({
    overallScore: MONTHLY_OVERALL_SCORES[MONTHLY_OVERALL_SCORES.length - 1],
    previousScore: previousMonthScore,
    capturedAt: admin.firestore.Timestamp.fromDate(ANCHOR),
    byDomain: BY_DOMAIN_TODAY,
    byDomainDelta30d: BY_DOMAIN_DELTA_30D,
    peerMedian: PEER_MEDIAN,
  });
}

async function seedPostureHistory(): Promise<void> {
  const batch = db.batch();
  for (let i = 0; i < MONTHLY_OVERALL_SCORES.length; i++) {
    const capturedAt = monthsBefore(ANCHOR, MONTHLY_OVERALL_SCORES.length - 1 - i);
    const delta30d = i === 0 ? 0 : MONTHLY_OVERALL_SCORES[i] - MONTHLY_OVERALL_SCORES[i - 1];
    // Id determinístico por mês (AAAA-MM) - reexecutar o seed sobrescreve o
    // mesmo ponto em vez de acumular pontos duplicados.
    const docId = `${capturedAt.getUTCFullYear()}-${String(capturedAt.getUTCMonth() + 1).padStart(2, "0")}`;
    const ref = db.doc(`tenants/${TENANT_ID}/posture_snapshots/${docId}`);
    batch.set(ref, {
      // A série é o índice GERAL mês a mês (mesma decisão do mock): o campo
      // `domain` existe só porque o schema é compartilhado com o
      // drill-down por domínio, marcado com o domínio que mais pesa na
      // narrativa do período.
      domain: "appsec",
      score: MONTHLY_OVERALL_SCORES[i],
      capturedAt: admin.firestore.Timestamp.fromDate(capturedAt),
      peerMedian: PEER_MEDIAN,
      delta30d,
    });
  }
  await batch.commit();
}

async function seedCompliance(): Promise<void> {
  const batch = db.batch();
  for (const control of COMPLIANCE_CONTROLS) {
    const ref = db.doc(`tenants/${TENANT_ID}/compliance/${control.controlId}`);
    batch.set(ref, {
      framework: control.framework,
      controlId: control.controlId,
      title: control.title,
      status: control.status,
      ownerName: control.ownerName,
      lastReviewedAt: admin.firestore.Timestamp.fromDate(
        daysBefore(ANCHOR, control.reviewedDaysAgo)
      ),
      domain: control.domain,
      evidenceUrl: evidenceFor(control.controlId, control.status),
    });
  }
  await batch.commit();
}

async function seedRisks(): Promise<void> {
  const batch = db.batch();
  for (const risk of RISKS) {
    const ref = db.doc(`tenants/${TENANT_ID}/risks/${risk.id}`);
    batch.set(ref, {
      id: risk.id,
      title: risk.title,
      businessUnit: risk.businessUnit,
      domain: risk.domain,
      inherentScore: risk.inherentScore,
      residualScore: risk.residualScore,
      annualLossExpectancy: risk.annualLossExpectancy,
      currency: risk.currency,
      treatment: risk.treatment,
      acceptance: risk.acceptance,
      reviewDueAt: admin.firestore.Timestamp.fromDate(daysAfter(ANCHOR, risk.reviewDueInDays)),
    });
  }
  await batch.commit();
}

async function seedInsights(): Promise<void> {
  const batch = db.batch();
  for (const insight of INSIGHTS) {
    const ref = db.doc(`tenants/${TENANT_ID}/insights/${insight.id}`);
    batch.set(ref, {
      id: insight.id,
      topic: insight.topic,
      title: insight.title,
      summary: insight.summary,
      publishedAt: admin.firestore.Timestamp.fromDate(daysBefore(ANCHOR, insight.publishedDaysAgo)),
      sourceName: "Elytron Threat Intelligence",
      sourceUrl: `https://insights.elytronsecurity.com/${insight.id}`,
      isBenchmark: insight.isBenchmark,
    });
  }
  await batch.commit();
}

async function seedSurvey(): Promise<void> {
  await db.doc(`tenants/${TENANT_ID}/surveys/${ACTIVE_SURVEY_ID}`).set({
    title: "Prioridades de segurança para 2027",
    description:
      "Leva menos de um minuto. Ao final, veja como sua resposta se compara " +
      "à de outros CISOs do seu setor.",
    active: true,
    respondentCount: 214,
    questions: [
      {
        id: "maior-obstaculo",
        prompt:
          "Qual é o maior obstáculo para reduzir as lacunas de compliance " +
          "na sua empresa hoje?",
        options: [
          "Orçamento insuficiente",
          "Falta de pessoal especializado",
          "Prioridade concorrente com outras áreas de TI",
          "Dificuldade em obter evidência dos donos de cada controle",
        ],
        peerDistribution: [34, 29, 21, 16],
      },
      {
        id: "prazo-reducao",
        prompt:
          "Em quanto tempo você espera reduzir pela metade o número de " +
          "lacunas abertas?",
        options: ["Até 3 meses", "De 3 a 6 meses", "De 6 a 12 meses", "Mais de 12 meses"],
        peerDistribution: [9, 31, 42, 18],
      },
      {
        id: "domínio-investido",
        prompt:
          "Qual domínio de segurança recebeu mais investimento da sua " +
          "empresa no último ano?",
        options: ["Identidade e Acesso", "Nuvem", "Segurança de Aplicações", "Terceiros"],
        peerDistribution: [38, 27, 24, 11],
      },
    ],
  });
}

// ---------------------------------------------------------------------------
// 4. Orquestração
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  console.log(
    `[seed] projeto=${projectId} modo=${isProd ? "PROD" : "emulador"} ` +
      `tenant=${TENANT_ID}`
  );

  await seedTenantDoc();
  await seedAuthAndMembers();
  await seedPostureIndex();
  await seedPostureHistory();
  await seedCompliance();
  await seedRisks();
  await seedInsights();
  await seedSurvey();

  console.log(
    "[seed] concluído: 1 tenant, 3 contas de demonstração, 12 snapshots de " +
      "postura, 24 controles de compliance, 6 riscos, 8 insights, 1 pesquisa " +
      "ativa."
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("[seed] falhou:", error);
    process.exit(1);
  });
