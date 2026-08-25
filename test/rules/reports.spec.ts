// Relatórios especialistas (prompt 11): leitura governada por
// classificação + persona + fato relevante, espelhando
// ReportAccessPolicy em Dart. Regra e classe precisam concordar.

import { doc, getDoc, setDoc } from 'firebase/firestore';
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

describe('reports/sections - canSeeSection por sensibilidade', () => {
  beforeEach(async () => {
    await seedReport('rep-confidential', { classification: 'confidential', materialFacts: [] });
    await seedSection('rep-confidential', 'sec-narrative', { sensitivity: 'narrative' });
    await seedSection('rep-confidential', 'sec-exploit', { sensitivity: 'exploit_proof' });
    await seedSection('rep-confidential', 'sec-personal', { sensitivity: 'personal_data' });
  });

  it('board lê narrative mas NÃO lê exploit_proof nem personal_data', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertSucceeds(
      getDoc(
        doc(bob.firestore(), 'tenants', TENANT_A, 'reports', 'rep-confidential', 'sections', 'sec-narrative'),
      ),
    );
    await assertFails(
      getDoc(
        doc(bob.firestore(), 'tenants', TENANT_A, 'reports', 'rep-confidential', 'sections', 'sec-exploit'),
      ),
    );
    await assertFails(
      getDoc(
        doc(bob.firestore(), 'tenants', TENANT_A, 'reports', 'rep-confidential', 'sections', 'sec-personal'),
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
