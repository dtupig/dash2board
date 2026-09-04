// Relatórios especialistas (prompt 11): leitura governada por
// classificação + persona + fato relevante, espelhando
// ReportAccessPolicy em Dart. Regra e classe precisam concordar.

import { strict as assert } from 'node:assert';
import {
  collection,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  setDoc,
  where,
} from 'firebase/firestore';
import {
  assertFails,
  assertSucceeds,
  env,
  personaContext,
  TENANT_A,
} from './helpers';

async function seedReport(id: string, data: Record<string, unknown>) {
  await env().withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), 'tenants', TENANT_A, 'reports', id), data);
  });
}

async function seedSection(
  reportId: string,
  sectionId: string,
  data: Record<string, unknown>,
) {
  await env().withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), 'tenants', TENANT_A, 'reports', reportId, 'sections', sectionId),
      data,
    );
  });
}

describe('reports - canOpen por classificação e persona', () => {
  beforeEach(async () => {
    await seedReport('rep-confidential', { classification: 'confidential', materialFacts: [] });
    await seedReport('rep-secret', { classification: 'secret', materialFacts: [] });
    await seedReport('rep-material-fact', {
      classification: 'confidential',
      materialFacts: [{ trigger: 'critical_internet_facing' }],
    });
  });

  it('strategic abre confidential e secret', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertSucceeds(
      getDoc(doc(carla.firestore(), 'tenants', TENANT_A, 'reports', 'rep-confidential')),
    );
    await assertSucceeds(
      getDoc(doc(carla.firestore(), 'tenants', TENANT_A, 'reports', 'rep-secret')),
    );
  });

  it('operational abre confidential mas NÃO abre secret', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    await assertSucceeds(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'reports', 'rep-confidential')),
    );
    await assertFails(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'reports', 'rep-secret')),
    );
  });

  it('board NÃO abre confidential sem fato relevante', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertFails(
      getDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'reports', 'rep-confidential')),
    );
  });

  it('board abre relatório com fato relevante', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertSucceeds(
      getDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'reports', 'rep-material-fact')),
    );
  });

  it('ninguém escreve relatório pelo app', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertFails(
      setDoc(doc(carla.firestore(), 'tenants', TENANT_A, 'reports', 'rep-new'), {
        classification: 'restricted',
      }),
    );
  });
});

// Achado 1 (docs/20_RETOMADA_SESSAO.md): uma query de lista sem `where`
// correspondente à regra derruba a query inteira se qualquer documento
// reprovar - diferente de `getDoc`, que só afeta o próprio documento. Os
// dois testes abaixo provam o bug (query sem `where`) e a correção (query
// com `where('audienceRoles', 'array-contains', ...)`).
describe('reports - list via audienceRoles (achado 1)', () => {
  beforeEach(async () => {
    await seedReport('rep-list-visivel', {
      classification: 'confidential',
      materialFacts: [],
      audienceRoles: ['operational', 'strategic', 'board'],
      deliveredAt: new Date('2026-01-01T00:00:00Z'),
    });
    await seedReport('rep-list-secreto', {
      classification: 'secret',
      materialFacts: [],
      audienceRoles: ['strategic'],
      deliveredAt: new Date('2026-01-02T00:00:00Z'),
    });
  });

  it('operational lista só os relatórios com seu papel em audienceRoles', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    const q = query(
      collection(alice.firestore(), 'tenants', TENANT_A, 'reports'),
      where('audienceRoles', 'array-contains', 'operational'),
      orderBy('deliveredAt', 'desc'),
    );
    const snapshot = await assertSucceeds(getDocs(q));
    assert.deepStrictEqual(
      snapshot.docs.map((d) => d.id),
      ['rep-list-visivel'],
    );
  });

  it('a mesma coleção SEM o where derruba a query inteira (o bug do achado 1)', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    const qSemWhere = query(
      collection(alice.firestore(), 'tenants', TENANT_A, 'reports'),
      orderBy('deliveredAt', 'desc'),
    );
    await assertFails(getDocs(qSemWhere));
  });
});

describe('reports/sections - canSeeSection por sensibilidade', () => {
  beforeEach(async () => {
    await seedReport('rep-confidential', { classification: 'confidential', materialFacts: [] });
    await seedSection('rep-confidential', 'sec-narrative', { sensitivity: 'narrative' });
    await seedSection('rep-confidential', 'sec-exploit', { sensitivity: 'exploit_proof' });
    await seedSection('rep-confidential', 'sec-personal', { sensitivity: 'personal_data' });

    // board só abre relatório com fato relevante (ou public_internal) - o
    // teste de canSeeSection para board precisa de um relatório que ele
    // consiga abrir, senão canOpenReport já barra tudo antes de chegar
    // em canSeeSection.
    await seedReport('rep-board-openable', {
      classification: 'confidential',
      materialFacts: [{ trigger: 'critical_internet_facing' }],
    });
    await seedSection('rep-board-openable', 'sec-narrative', { sensitivity: 'narrative' });
    await seedSection('rep-board-openable', 'sec-exploit', { sensitivity: 'exploit_proof' });
    await seedSection('rep-board-openable', 'sec-personal', { sensitivity: 'personal_data' });
  });

  it('board lê narrative mas NÃO lê exploit_proof nem personal_data', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertSucceeds(
      getDoc(
        doc(bob.firestore(), 'tenants', TENANT_A, 'reports', 'rep-board-openable', 'sections', 'sec-narrative'),
      ),
    );
    await assertFails(
      getDoc(
        doc(bob.firestore(), 'tenants', TENANT_A, 'reports', 'rep-board-openable', 'sections', 'sec-exploit'),
      ),
    );
    await assertFails(
      getDoc(
        doc(bob.firestore(), 'tenants', TENANT_A, 'reports', 'rep-board-openable', 'sections', 'sec-personal'),
      ),
    );
  });

  it('operational lê exploit_proof em confidential mas NÃO lê personal_data', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    await assertSucceeds(
      getDoc(
        doc(alice.firestore(), 'tenants', TENANT_A, 'reports', 'rep-confidential', 'sections', 'sec-exploit'),
      ),
    );
    await assertFails(
      getDoc(
        doc(alice.firestore(), 'tenants', TENANT_A, 'reports', 'rep-confidential', 'sections', 'sec-personal'),
      ),
    );
  });

  it('strategic lê todas as sensibilidades', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertSucceeds(
      getDoc(
        doc(carla.firestore(), 'tenants', TENANT_A, 'reports', 'rep-confidential', 'sections', 'sec-personal'),
      ),
    );
  });
});

// Achado 5 (docs/20_RETOMADA_SESSAO.md): mesmo bug do achado 1, mas em
// `reports/{reportId}/sections` - uma query de lista sem `where`
// correspondente à regra derruba a query inteira se qualquer seção
// individual reprovar `canSeeSection`. Os dois testes abaixo provam o bug
// (query sem `where`) e a correção (query com
// `where('visibleRoles', 'array-contains', ...)`).
describe('reports/sections - list via visibleRoles (achado 5)', () => {
  beforeEach(async () => {
    await seedReport('rep-list-secoes', { classification: 'confidential', materialFacts: [] });
    await seedSection('rep-list-secoes', 'sec-narrative', {
      sensitivity: 'narrative',
      visibleRoles: ['operational', 'strategic', 'board'],
    });
    await seedSection('rep-list-secoes', 'sec-personal', {
      sensitivity: 'personal_data',
      visibleRoles: ['strategic'],
    });
  });

  it('operational lista só as seções com seu papel em visibleRoles', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    const q = query(
      collection(
        alice.firestore(), 'tenants', TENANT_A, 'reports', 'rep-list-secoes', 'sections',
      ),
      where('visibleRoles', 'array-contains', 'operational'),
    );
    const snapshot = await assertSucceeds(getDocs(q));
    assert.deepStrictEqual(
      snapshot.docs.map((d) => d.id),
      ['sec-narrative'],
    );
  });

  it('a mesma subcoleção SEM o where derruba a query inteira (o bug do achado 5)', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    const qSemWhere = query(
      collection(
        alice.firestore(), 'tenants', TENANT_A, 'reports', 'rep-list-secoes', 'sections',
      ),
    );
    await assertFails(getDocs(qSemWhere));
  });
});
