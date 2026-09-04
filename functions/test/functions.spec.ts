// Cobertura mínima das Cloud Functions (docs/21_BACKLOG_ACHADOS_TECNICOS.md,
// item 4): um caso positivo e um negativo por function, chamando cada
// handler exportado direto (ver nota em `helpers.ts` sobre por que isso é
// diferente do padrão de `test/rules/`). Usa o Admin SDK real contra os
// emuladores Firestore/Auth - a mesma dupla que as functions usam em
// produção -, então cada `assert` confere estado real, não um mock.

import {strict as assert} from 'node:assert';
import * as admin from 'firebase-admin';
import {
  handleAssignRole,
  handleClaimInvite,
  handleGateSignUp,
  handleLogRiskDecision,
  handleRecordReadReceipt,
  handleSyncMemberClaims,
} from '../src/index';
import {makeCallableRequest, makeFirestoreEvent} from './helpers';

async function assertHttpsErrorCode(
  promise: Promise<unknown>,
  expectedCode: string
): Promise<void> {
  try {
    await promise;
    assert.fail(`esperava HttpsError '${expectedCode}', mas não lançou`);
  } catch (error) {
    assert.equal((error as {code?: string}).code, expectedCode);
  }
}

async function auditLogs(tenantId: string) {
  const snap = await admin
    .firestore()
    .collection(`tenants/${tenantId}/audit_logs`)
    .get();
  return snap.docs.map((doc) => doc.data());
}

describe('gateSignUp - admissão por allowlist de convite', () => {
  it('convite válido devolve os custom claims do convite', async () => {
    await admin.firestore().doc('invites/alice@demo.elytron').set({
      tenantId: 'tenant-a',
      role: 'operational',
    });

    const result = await handleGateSignUp({
      data: {email: 'ALICE@demo.elytron'},
    } as never);

    assert.deepEqual(result, {
      customClaims: {role: 'operational', tenantId: 'tenant-a', tenantAdmin: false},
    });
  });

  it('sem convite, nega o cadastro', async () => {
    await assertHttpsErrorCode(
      handleGateSignUp({data: {email: 'bob@demo.elytron'}} as never),
      'permission-denied'
    );
  });
});

describe('syncMemberClaims - sincroniza claims com o documento de membro', () => {
  beforeEach(async () => {
    await admin.auth().createUser({uid: 'user-1', email: 'user1@demo.elytron'});
  });

  it('papel alterado atualiza claims e registra auditoria', async () => {
    await handleSyncMemberClaims(
      makeFirestoreEvent(
        {tenantId: 'tenant-a', uid: 'user-1'},
        {role: 'operational', tenantAdmin: false},
        {role: 'strategic', tenantAdmin: false}
      )
    );

    const user = await admin.auth().getUser('user-1');
    assert.deepEqual(user.customClaims, {
      role: 'strategic',
      tenantId: 'tenant-a',
      tenantAdmin: false,
    });

    const logs = await auditLogs('tenant-a');
    assert.equal(logs.length, 1);
    assert.equal(logs[0].action, 'member.role_changed');
  });

  it('sem mudança de papel/tenantAdmin, não escreve claims nem auditoria', async () => {
    await handleSyncMemberClaims(
      makeFirestoreEvent(
        {tenantId: 'tenant-a', uid: 'user-1'},
        {role: 'operational', tenantAdmin: false},
        {role: 'operational', tenantAdmin: false, displayName: 'Novo nome'}
      )
    );

    const user = await admin.auth().getUser('user-1');
    assert.equal(user.customClaims, undefined);
    assert.deepEqual(await auditLogs('tenant-a'), []);
  });
});

describe('logRiskDecision - auditoria de decisão de risco do board', () => {
  it('decisão nova registra auditoria', async () => {
    await handleLogRiskDecision(
      makeFirestoreEvent(
        {tenantId: 'tenant-a', riskId: 'risk-1'},
        undefined,
        {acceptance: 'accepted', acceptedByUid: 'ciso-1', boardNote: 'ok'}
      )
    );

    const logs = await auditLogs('tenant-a');
    assert.equal(logs.length, 1);
    assert.equal(logs[0].action, 'risk.decision_recorded');
    assert.equal((logs[0].payload as {decision: string}).decision, 'accepted');
  });

  it('regravação com a mesma decisão não duplica a auditoria', async () => {
    await handleLogRiskDecision(
      makeFirestoreEvent(
        {tenantId: 'tenant-a', riskId: 'risk-1'},
        {acceptance: 'accepted'},
        {acceptance: 'accepted', acceptedByUid: 'ciso-1'}
      )
    );

    assert.deepEqual(await auditLogs('tenant-a'), []);
  });
});

describe('assignRole - administrador do tenant atribui persona', () => {
  beforeEach(async () => {
    await admin.firestore().doc('tenants/tenant-a/members/user-2').set({
      role: 'operational',
    });
  });

  it('admin do tenant promove um membro existente', async () => {
    const result = await handleAssignRole(
      makeCallableRequest(
        {targetUid: 'user-2', role: 'strategic'},
        {uid: 'admin-1', token: {tenantId: 'tenant-a', tenantAdmin: true}}
      )
    );

    assert.deepEqual(result, {ok: true, role: 'strategic'});

    const member = await admin
      .firestore()
      .doc('tenants/tenant-a/members/user-2')
      .get();
    assert.equal(member.data()?.role, 'strategic');
  });

  it('quem não é admin do tenant não pode atribuir papel', async () => {
    await assertHttpsErrorCode(
      handleAssignRole(
        makeCallableRequest(
          {targetUid: 'user-2', role: 'strategic'},
          {uid: 'user-3', token: {tenantId: 'tenant-a', tenantAdmin: false}}
        )
      ),
      'permission-denied'
    );
  });
});

describe('claimInvite - consome o convite no primeiro login', () => {
  it('convite válido cria o membro e marca consumedAt', async () => {
    await admin.firestore().doc('invites/carol@demo.elytron').set({
      tenantId: 'tenant-b',
      role: 'board',
    });

    const result = await handleClaimInvite(
      makeCallableRequest({}, {uid: 'user-4', token: {email: 'carol@demo.elytron'}})
    );

    assert.deepEqual(result, {ok: true, role: 'board', tenantId: 'tenant-b'});

    const member = await admin
      .firestore()
      .doc('tenants/tenant-b/members/user-4')
      .get();
    assert.equal(member.data()?.role, 'board');

    const invite = await admin.firestore().doc('invites/carol@demo.elytron').get();
    assert.notEqual(invite.data()?.consumedAt, undefined);
  });

  it('sem convite pendente, recusa', async () => {
    await assertHttpsErrorCode(
      handleClaimInvite(
        makeCallableRequest({}, {uid: 'user-5', token: {email: 'dave@demo.elytron'}})
      ),
      'not-found'
    );
  });
});

describe('recordReadReceipt - registro de leitura de relatório', () => {
  it('strategic registra leitura de qualquer classificação', async () => {
    await admin.firestore().doc('tenants/tenant-a/reports/rep-1').set({
      classification: 'confidential',
      materialFacts: [],
    });

    const result = await handleRecordReadReceipt(
      makeCallableRequest(
        {reportId: 'rep-1'},
        {uid: 'user-6', token: {tenantId: 'tenant-a', role: 'strategic'}}
      )
    );

    assert.deepEqual(result, {ok: true});
    const logs = await auditLogs('tenant-a');
    assert.equal(logs.length, 1);
    assert.equal(logs[0].action, 'report.read_receipt');
  });

  it('operational não registra leitura de relatório secret', async () => {
    await admin.firestore().doc('tenants/tenant-a/reports/rep-2').set({
      classification: 'secret',
      materialFacts: [],
    });

    await assertHttpsErrorCode(
      handleRecordReadReceipt(
        makeCallableRequest(
          {reportId: 'rep-2'},
          {uid: 'user-7', token: {tenantId: 'tenant-a', role: 'operational'}}
        )
      ),
      'permission-denied'
    );
  });
});
