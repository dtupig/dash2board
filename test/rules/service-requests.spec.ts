// Alçada do módulo de serviços (prompt 10): operacional abre e só lê as
// próprias; CISO aprova/rejeita e lê todas; board só lê com fato relevante
// (ainda inexistente hoje, então nenhuma). Espelha RequestPolicy em Dart.

import { deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import {
  assertFails,
  assertSucceeds,
  env,
  personaContext,
  TENANT_A,
} from './helpers';

describe('contracted_services - leitura das três personas, escrita só backend', () => {
  beforeEach(async () => {
    await env().withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'tenants', TENANT_A, 'contracted_services', 'web_api'),
        { serviceKey: 'web_api', status: 'active' },
      );
    });
  });

  it('operational lê contracted_services', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    await assertSucceeds(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'contracted_services', 'web_api')),
    );
  });

  it('strategic lê contracted_services', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertSucceeds(
      getDoc(doc(carla.firestore(), 'tenants', TENANT_A, 'contracted_services', 'web_api')),
    );
  });

  it('board lê contracted_services', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertSucceeds(
      getDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'contracted_services', 'web_api')),
    );
  });

  it('ninguém escreve contracted_services pelo app', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertFails(
      setDoc(doc(carla.firestore(), 'tenants', TENANT_A, 'contracted_services', 'dast'), {
        serviceKey: 'dast',
      }),
    );
  });
});

describe('service_requests - leitura por alçada', () => {
  beforeEach(async () => {
    await env().withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'tenants', TENANT_A, 'service_requests', 'req-alice'), {
        requestedByUid: 'alice',
        status: 'pending_approval',
      });
      await setDoc(doc(db, 'tenants', TENANT_A, 'service_requests', 'req-outro'), {
        requestedByUid: 'outro-uid',
        status: 'approved',
      });
      await setDoc(doc(db, 'tenants', TENANT_A, 'service_requests', 'req-material'), {
        requestedByUid: 'outro-uid',
        status: 'sent_to_elytron',
        materialFact: true,
      });
    });
  });

  it('operational lê a própria solicitação', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    await assertSucceeds(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-alice')),
    );
  });

  it('operational NÃO lê solicitação de outro solicitante', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    await assertFails(
      getDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-outro')),
    );
  });

  it('strategic lê todas as solicitações do tenant', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertSucceeds(
      getDoc(doc(carla.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-outro')),
    );
  });

  it('board NÃO lê solicitação sem fato relevante', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertFails(
      getDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-outro')),
    );
  });

  it('board lê solicitação marcada como fato relevante', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertSucceeds(
      getDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-material')),
    );
  });
});

describe('service_requests - criação coerente com a alçada', () => {
  it('operational cria a própria solicitação nascendo pending_approval', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    await assertSucceeds(
      setDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-1'), {
        requestedByUid: 'alice',
        status: 'pending_approval',
      }),
    );
  });

  it('operational NÃO cria solicitação já aprovada', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    await assertFails(
      setDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-2'), {
        requestedByUid: 'alice',
        status: 'approved',
      }),
    );
  });

  it('strategic cria a própria solicitação já auto-aprovada', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertSucceeds(
      setDoc(doc(carla.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-3'), {
        requestedByUid: 'carla',
        status: 'approved',
      }),
    );
  });

  it('ninguém cria solicitação em nome de outro uid', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    await assertFails(
      setDoc(doc(alice.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-4'), {
        requestedByUid: 'outro-uid',
        status: 'pending_approval',
      }),
    );
  });

  it('board NÃO cria solicitação', async () => {
    const bob = personaContext('bob', { tenantId: TENANT_A, role: 'board' });
    await assertFails(
      setDoc(doc(bob.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-5'), {
        requestedByUid: 'bob',
        status: 'pending_approval',
      }),
    );
  });
});

describe('service_requests - decisão de aprovação só do strategic', () => {
  beforeEach(async () => {
    await env().withSecurityRulesDisabled(async (context) => {
      await setDoc(
        doc(context.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-decidir'),
        { requestedByUid: 'alice', status: 'pending_approval' },
      );
    });
  });

  it('strategic aprova, mudando só status/approval/updatedAt', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertSucceeds(
      updateDoc(
        doc(carla.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-decidir'),
        { status: 'approved', approval: { decision: 'approved' }, updatedAt: 1 },
      ),
    );
  });

  it('operational NÃO aprova a própria solicitação', async () => {
    const alice = personaContext('alice', { tenantId: TENANT_A, role: 'operational' });
    await assertFails(
      updateDoc(
        doc(alice.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-decidir'),
        { status: 'approved' },
      ),
    );
  });

  it('strategic NÃO altera campo fora da lista permitida', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertFails(
      updateDoc(
        doc(carla.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-decidir'),
        { status: 'approved', requestedByUid: 'carla' },
      ),
    );
  });

  it('ninguém apaga uma solicitação - nem o CISO', async () => {
    const carla = personaContext('carla', { tenantId: TENANT_A, role: 'strategic' });
    await assertFails(
      deleteDoc(
        doc(carla.firestore(), 'tenants', TENANT_A, 'service_requests', 'req-decidir'),
      ),
    );
  });
});
