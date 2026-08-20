// Utilidades compartilhadas pelos testes de firestore.rules. Um único
// RulesTestEnvironment é criado uma vez (ver root-hooks.ts) e reaproveitado
// por todos os arquivos *.spec.ts, com o Firestore limpo entre casos.

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

// Precisa bater com o projeto do emulador (--project em package.json e o
// alias "default" do .firebaserc): em singleProjectMode, um id diferente
// aqui gera um aviso "Multiple projectIds" no log do emulador.
export const PROJECT_ID = 'elytron-d2b-dev';

export const TENANT_A = 'tenant-a';
export const TENANT_B = 'tenant-b';

let testEnv: RulesTestEnvironment;

export async function setupTestEnv(): Promise<void> {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
}

export function env(): RulesTestEnvironment {
  return testEnv;
}

export async function teardownTestEnv(): Promise<void> {
  await testEnv.cleanup();
}

// Espelha exatamente os custom claims que o backend assina no ID token —
// é a única fonte de autoridade que as regras consultam (nunca o Firestore).
export type PersonaClaims = {
  tenantId: string;
  role: 'operational' | 'strategic' | 'board';
  tenantAdmin?: boolean;
};

export function personaContext(uid: string, claims: PersonaClaims) {
  return testEnv.authenticatedContext(uid, claims);
}

export { assertFails, assertSucceeds };
