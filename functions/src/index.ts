/**
 * Elytron Dash2Board - Cloud Functions
 *
 * Responsabilidades (nenhuma delas pode ficar no cliente):
 *  1. Admitir apenas contas convidadas pela organização (allowlist);
 *  2. Provisionar `role` e `tenantId` como CUSTOM CLAIMS assinados;
 *  3. Manter claim e documento de membro sincronizados;
 *  4. Registrar trilha de auditoria imutável de tudo que muda acesso.
 *
 * As três personas do produto:
 *   operational -> time técnico operacional e tático
 *   strategic   -> segurança estratégica e CISO
 *   board       -> C-Level das unidades de negócio
 */

import * as admin from "firebase-admin";
import {setGlobalOptions} from "firebase-functions/v2";
import {onDocumentWritten} from "firebase-functions/v2/firestore";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {beforeUserCreated} from "firebase-functions/v2/identity";
import {logger} from "firebase-functions";

admin.initializeApp();

const db = admin.firestore();

/** Região padrão: São Paulo, para latência e residência de dados no Brasil. */
setGlobalOptions({region: "southamerica-east1", maxInstances: 20});

/** Blocking functions de identidade rodam em us-central1. */
const IDENTITY_REGION = "us-central1";

export const ROLES = ["operational", "strategic", "board", "pending"] as const;
export type Role = (typeof ROLES)[number];

function isRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as readonly string[]).includes(value);
}

interface InviteDoc {
  tenantId: string;
  role: Role;
  tenantAdmin?: boolean;
  displayName?: string;
  jobTitle?: string;
  businessUnit?: string;
  consumedAt?: admin.firestore.Timestamp | null;
}

/** Escreve um evento imutável na trilha de auditoria do tenant. */
async function writeAudit(
  tenantId: string,
  action: string,
  actorUid: string,
  payload: Record<string, unknown>
): Promise<void> {
  if (!tenantId) {
    return;
  }
  await db.collection(`tenants/${tenantId}/audit_logs`).add({
    action,
    actorUid,
    payload,
    at: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// ---------------------------------------------------------------------------
// 1. Admissão: só entra quem foi convidado
// ---------------------------------------------------------------------------

/**
 * Bloqueia a criação de contas fora da allowlist de convites.
 * O convite é indexado pelo e-mail em minúsculas: /invites/{email}
 */
export const gateSignUp = beforeUserCreated(
  {region: IDENTITY_REGION},
  async (event) => {
    const email = event.data?.email?.toLowerCase();

    if (!email) {
      throw new HttpsError(
        "permission-denied",
        "É necessário um e-mail corporativo para acessar o Dash2Board."
      );
    }

    const inviteSnap = await db.doc(`invites/${email}`).get();

    if (!inviteSnap.exists) {
      logger.warn("Tentativa de cadastro sem convite", {email});
      throw new HttpsError(
        "permission-denied",
        "Esta conta não está autorizada. Fale com o administrador da sua organização."
      );
    }

    const invite = inviteSnap.data() as InviteDoc;

    if (!invite.tenantId || !isRole(invite.role)) {
      throw new HttpsError(
        "failed-precondition",
        "Convite inválido. Fale com o suporte da Elytron."
      );
    }

    // Claims iniciais já saem no primeiro token emitido.
    return {
      customClaims: {
        role: invite.role,
        tenantId: invite.tenantId,
        tenantAdmin: invite.tenantAdmin === true,
      },
    };
  }
);

// ---------------------------------------------------------------------------
// 2. Provisionamento do membro + sincronização de claims
// ---------------------------------------------------------------------------

/**
 * Mantém os custom claims em sincronia com o documento de membro.
 * É a única rota pela qual o papel de um usuário muda de fato.
 */
export const syncMemberClaims = onDocumentWritten(
  "tenants/{tenantId}/members/{uid}",
  async (event) => {
    const {tenantId, uid} = event.params;
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();

    if (!after) {
      // Membro removido: derruba o acesso imediatamente.
      await admin.auth().setCustomUserClaims(uid, {
        role: "pending",
        tenantId: "",
        tenantAdmin: false,
      });
      await admin.auth().revokeRefreshTokens(uid);
      await writeAudit(tenantId, "member.removed", "system", {uid});
      return;
    }

    const role: Role = isRole(after.role) ? after.role : "pending";
    const tenantAdmin = after.tenantAdmin === true;
    const changed =
      before?.role !== after.role || before?.tenantAdmin !== after.tenantAdmin;

    if (!changed) {
      return;
    }

    await admin.auth().setCustomUserClaims(uid, {
      role,
      tenantId,
      tenantAdmin,
    });

    // Força a emissão de um novo ID token com os claims atualizados.
    await admin.auth().revokeRefreshTokens(uid);

    await db.doc(`users/${uid}`).set(
      {
        tenantId,
        role,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    await writeAudit(tenantId, "member.role_changed", "system", {
      uid,
      from: before?.role ?? null,
      to: role,
      tenantAdmin,
    });

    logger.info("Claims sincronizados", {uid, tenantId, role});
  }
);

// ---------------------------------------------------------------------------
// 2b. Trilha de auditoria de decisões de risco (painel do board)
// ---------------------------------------------------------------------------

const RISK_DECISIONS = ["accepted", "rejected", "plan_requested"] as const;
type RiskDecision = (typeof RISK_DECISIONS)[number];

function isRiskDecision(value: unknown): value is RiskDecision {
  return (
    typeof value === "string" &&
    (RISK_DECISIONS as readonly string[]).includes(value)
  );
}

/**
 * `firestore.rules` só libera, para o papel `board`, a escrita dos campos
 * `acceptance`/`acceptedByUid`/`acceptedAt`/`boardNote`/`updatedAt` em
 * `risks/{riskId}` - nunca o valor do risco em si. Esta function observa
 * essa escrita e registra o evento na trilha de auditoria, que o cliente
 * não pode ler nem escrever diretamente.
 */
export const logRiskDecision = onDocumentWritten(
  "tenants/{tenantId}/risks/{riskId}",
  async (event) => {
    const {tenantId, riskId} = event.params;
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();

    if (!after || !isRiskDecision(after.acceptance)) {
      return;
    }
    if (before?.acceptance === after.acceptance) {
      // Já registrado nesta decisão - evita duplicar a entrada de auditoria
      // se o documento for regravado sem mudança de fato (ex.: retry).
      return;
    }

    await writeAudit(tenantId, "risk.decision_recorded", after.acceptedByUid ?? "unknown", {
      riskId,
      decision: after.acceptance,
      boardNote: after.boardNote ?? null,
    });

    logger.info("Decisão de risco registrada na auditoria", {
      tenantId,
      riskId,
      decision: after.acceptance,
    });
  }
);

// ---------------------------------------------------------------------------
// 3. Callable: administrador do tenant atribui/altera persona
// ---------------------------------------------------------------------------

interface AssignRoleRequest {
  targetUid?: string;
  role?: string;
  tenantAdmin?: boolean;
}

export const assignRole = onCall<AssignRoleRequest>(async (request) => {
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Sessão inválida.");
  }

  const callerTenant = (auth.token.tenantId as string | undefined) ?? "";
  const callerIsAdmin = auth.token.tenantAdmin === true;

  if (!callerTenant || !callerIsAdmin) {
    throw new HttpsError(
      "permission-denied",
      "Apenas administradores da organização podem alterar perfis."
    );
  }

  const {targetUid, role, tenantAdmin} = request.data;

  if (!targetUid || !isRole(role)) {
    throw new HttpsError("invalid-argument", "Usuário ou perfil inválido.");
  }

  if (targetUid === auth.uid && role !== "strategic") {
    throw new HttpsError(
      "failed-precondition",
      "Um administrador não pode rebaixar o próprio acesso."
    );
  }

  const memberRef = db.doc(`tenants/${callerTenant}/members/${targetUid}`);
  const memberSnap = await memberRef.get();

  if (!memberSnap.exists) {
    throw new HttpsError(
      "not-found",
      "Usuário não pertence a esta organização."
    );
  }

  // A escrita abaixo dispara `syncMemberClaims`, que aplica os claims.
  await memberRef.set(
    {
      role,
      tenantAdmin: tenantAdmin === true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  await writeAudit(callerTenant, "member.role_assigned", auth.uid, {
    targetUid,
    role,
    tenantAdmin: tenantAdmin === true,
  });

  return {ok: true, role};
});

// ---------------------------------------------------------------------------
// 4. Callable: consome o convite e cria o membro no primeiro login
// ---------------------------------------------------------------------------

export const claimInvite = onCall(async (request) => {
  const auth = request.auth;

  if (!auth) {
    throw new HttpsError("unauthenticated", "Sessão inválida.");
  }

  const email = (auth.token.email as string | undefined)?.toLowerCase();

  if (!email) {
    throw new HttpsError("failed-precondition", "Conta sem e-mail.");
  }

  const inviteRef = db.doc(`invites/${email}`);
  const inviteSnap = await inviteRef.get();

  if (!inviteSnap.exists) {
    throw new HttpsError("not-found", "Nenhum convite pendente para esta conta.");
  }

  const invite = inviteSnap.data() as InviteDoc;

  if (!invite.tenantId || !isRole(invite.role)) {
    throw new HttpsError("failed-precondition", "Convite inválido.");
  }

  await db.doc(`tenants/${invite.tenantId}/members/${auth.uid}`).set(
    {
      uid: auth.uid,
      email,
      role: invite.role,
      tenantId: invite.tenantId,
      tenantAdmin: invite.tenantAdmin === true,
      displayName: invite.displayName ?? null,
      jobTitle: invite.jobTitle ?? null,
      businessUnit: invite.businessUnit ?? null,
      status: "active",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    {merge: true}
  );

  await inviteRef.set(
    {consumedAt: admin.firestore.FieldValue.serverTimestamp()},
    {merge: true}
  );

  await writeAudit(invite.tenantId, "invite.claimed", auth.uid, {email});

  return {ok: true, role: invite.role, tenantId: invite.tenantId};
});

// ---------------------------------------------------------------------------
// 5. Callable: registro de leitura de relatório sigiloso
// ---------------------------------------------------------------------------

interface ReportDoc {
  classification?: string;
  materialFacts?: unknown[];
}

/**
 * Espelha `ReportAccessPolicy.canOpen` (Dart) e `canOpenReport`
 * (firestore.rules) - as três precisam concordar; divergência entre elas é
 * falha de segurança, não detalhe.
 */
function canOpenReport(
  role: Role,
  classification: string,
  isMaterialFact: boolean
): boolean {
  switch (role) {
    case "strategic":
      return true;
    case "operational":
      return classification !== "secret";
    case "board":
      return isMaterialFact || classification === "public_internal";
    case "pending":
    default:
      return false;
  }
}

interface RecordReadReceiptRequest {
  reportId?: string;
}

/**
 * O cliente nunca escreve em `audit_logs` (regra fail-closed do projeto) -
 * esta function grava o registro de leitura de um relatório antes de o
 * conteúdo ser exibido (`ReportAccessPolicy.requiresReadReceipt`, hoje só
 * `secret`). Recalcula o acesso a partir do documento real via Admin SDK
 * em vez de confiar em qualquer coisa que o cliente afirme.
 */
export const recordReadReceipt = onCall<RecordReadReceiptRequest>(
  async (request) => {
    const auth = request.auth;

    if (!auth) {
      throw new HttpsError("unauthenticated", "Sessão inválida.");
    }

    const tenantId = (auth.token.tenantId as string | undefined) ?? "";
    const role: Role = isRole(auth.token.role) ? auth.token.role : "pending";

    if (!tenantId) {
      throw new HttpsError(
        "permission-denied",
        "Sua conta ainda não tem organização associada."
      );
    }

    const {reportId} = request.data;

    if (!reportId) {
      throw new HttpsError("invalid-argument", "Relatório inválido.");
    }

    const reportSnap = await db
      .doc(`tenants/${tenantId}/reports/${reportId}`)
      .get();

    if (!reportSnap.exists) {
      throw new HttpsError("not-found", "Relatório não encontrado.");
    }

    const report = reportSnap.data() as ReportDoc;
    const classification = report.classification ?? "secret";
    const isMaterialFact =
      Array.isArray(report.materialFacts) && report.materialFacts.length > 0;

    if (!canOpenReport(role, classification, isMaterialFact)) {
      throw new HttpsError(
        "permission-denied",
        "Seu perfil não tem acesso a este relatório."
      );
    }

    await writeAudit(tenantId, "report.read_receipt", auth.uid, {
      reportId,
      classification,
    });

    return {ok: true};
  }
);
