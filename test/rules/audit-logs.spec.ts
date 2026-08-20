// audit_logs é append-only e ilegível pelo app: nenhuma persona lê, e só o
// Admin SDK (aqui simulado por withSecurityRulesDisabled) grava.

import { doc, getDoc, setDoc } from 'firebase/firestore';
import {
  assertFails,
  assertSucceeds,
  env,
  personaContext,
  TENANT_A,
} from './helpers';

describe('audit_logs é ilegível e inescrível pelo app', () => {
  beforeEach(async () => {
    await env().withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'tenants', TENANT_A, 'audit_logs', 'log-1'),
        { action: 'login' },
      );
    });
  });

  it('operational NÃO lê audit_logs', async () => {
    const alice = personaContext('alice', {
      tenantId: TENANT_A,
      role: 'operational',
    });
    await assertFails(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'audit_logs', 'log-1')),
    );
  });

  it('strategic (CISO) NÃO lê audit_logs', async () => {
    const carla = personaContext('carla', {
      tenantId: TENANT_A,
      role: 'strategic',
    });
    await assertFails(
      getDoc(doc(carla.firestore(), 'tenants', TENANT_A, 'audit_logs', 'log-1')),
    );
  });

  it('board NÃO lê audit_logs', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertFails(
      getDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'audit_logs', 'log-1')),
    );
  });

  it('tenantAdmin NÃO escreve em audit_logs pelo app — só o Admin SDK grava', async () => {
    const admin = personaContext('admin', {
      tenantId: TENANT_A,
      role: 'strategic',
      tenantAdmin: true,
    });
    await assertFails(
      setDoc(doc(admin.firestore(), 'tenants', TENANT_A, 'audit_logs', 'log-2'), {
        action: 'x',
      }),
    );
  });

  it('a trilha é gravável só via bypass administrativo (Admin SDK)', async () => {
    await env().withSecurityRulesDisabled(async (context) => {
      await assertSucceeds(
        setDoc(
          doc(context.firestore(), 'tenants', TENANT_A, 'audit_logs', 'log-3'),
          { action: 'y' },
        ),
      );
    });
  });
});
