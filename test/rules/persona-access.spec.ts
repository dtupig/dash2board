// A persona board nunca vê incidents/compliance; a persona operational nunca
// vê risks. Cada negativo tem um positivo ao lado para provar que o papel
// não está simplesmente bloqueado por completo.

import { doc, getDoc, setDoc } from 'firebase/firestore';
import {
  assertFails,
  assertSucceeds,
  env,
  personaContext,
  TENANT_A,
} from './helpers';

describe('Acesso por persona', () => {
  beforeEach(async () => {
    await env().withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'tenants', TENANT_A, 'incidents', 'inc-1'), {
        title: 'x',
      });
      await setDoc(doc(db, 'tenants', TENANT_A, 'compliance', 'ctrl-1'), {
        title: 'x',
      });
      await setDoc(doc(db, 'tenants', TENANT_A, 'risks', 'risk-1'), {
        title: 'x',
      });
    });
  });

  it('board NÃO lê incidents', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertFails(
      getDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'incidents', 'inc-1')),
    );
  });

  it('board NÃO lê compliance', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertFails(
      getDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'compliance', 'ctrl-1')),
    );
  });

  it('board lê risks — prova que o papel não está bloqueado por completo', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertSucceeds(
      getDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'risks', 'risk-1')),
    );
  });

  it('operational NÃO lê risks', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertFails(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'risks', 'risk-1')),
    );
  });

  it('operational lê incidents — prova que o papel não está bloqueado por completo', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertSucceeds(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'incidents', 'inc-1')),
    );
  });
});
