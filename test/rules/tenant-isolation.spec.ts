// Fronteira principal do produto: nenhum documento de um tenant é
// alcançável por outro. Achado A-02 / invariante de segurança do CLAUDE.md.

import { doc, getDoc, setDoc } from 'firebase/firestore';
import {
  assertFails,
  assertSucceeds,
  env,
  personaContext,
  TENANT_A,
  TENANT_B,
} from './helpers';

describe('Isolamento entre tenants', () => {
  beforeEach(async () => {
    await env().withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'tenants', TENANT_A), { name: 'Tenant A' });
      await setDoc(doc(db, 'tenants', TENANT_B), { name: 'Tenant B' });
      await setDoc(doc(db, 'tenants', TENANT_A, 'incidents', 'inc-1'), {
        title: 'Incidente do tenant A',
      });
      await setDoc(doc(db, 'tenants', TENANT_B, 'incidents', 'inc-1'), {
        title: 'Incidente do tenant B',
      });
    });
  });

  it('operacional do tenant A lê o próprio incidente', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertSucceeds(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'incidents', 'inc-1')),
    );
  });

  it('operacional do tenant A NÃO lê o incidente do tenant B', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertFails(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_B, 'incidents', 'inc-1')),
    );
  });

  it('membro do tenant A lê o documento raiz do próprio tenant', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertSucceeds(getDoc(doc(alice.firestore(), 'tenants', TENANT_A)));
  });

  it('membro do tenant A NÃO lê o documento raiz do tenant B', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertFails(getDoc(doc(alice.firestore(), 'tenants', TENANT_B)));
  });
});
