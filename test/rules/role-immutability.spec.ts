// O papel do usuário vem de custom claims, nunca do cliente. O cliente pode
// editar o próprio perfil, mas nunca role/tenantId/tenantAdmin — nem em
// /users nem no espelho em /tenants/{t}/members.

import { doc, setDoc, updateDoc } from 'firebase/firestore';
import { assertFails, assertSucceeds, env, personaContext, TENANT_A } from './helpers';

describe('Cliente não escreve o próprio papel', () => {
  beforeEach(async () => {
    await env().withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'users', 'alice'), {
        tenantId: TENANT_A,
        role: 'operational',
        displayName: 'Alice',
      });
      await setDoc(doc(db, 'tenants', TENANT_A, 'members', 'alice'), {
        uid: 'alice',
        tenantId: TENANT_A,
        role: 'operational',
        tenantAdmin: false,
        status: 'active',
        displayName: 'Alice',
      });
    });
  });

  it('usuário atualiza o próprio displayName em /users', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertSucceeds(
      updateDoc(doc(alice.firestore(), 'users', 'alice'), {
        displayName: 'Alice Silva',
      }),
    );
  });

  it('usuário NÃO altera o próprio role em /users', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertFails(
      updateDoc(doc(alice.firestore(), 'users', 'alice'), { role: 'board' }),
    );
  });

  it('usuário NÃO altera o próprio role em members/', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertFails(
      updateDoc(
        doc(alice.firestore(), 'tenants', TENANT_A, 'members', 'alice'),
        { role: 'board' },
      ),
    );
  });

  it('usuário NÃO se autopromove a tenantAdmin em members/', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertFails(
      updateDoc(
        doc(alice.firestore(), 'tenants', TENANT_A, 'members', 'alice'),
        { tenantAdmin: true },
      ),
    );
  });
});
