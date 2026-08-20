// Root hook plugin do Mocha: sobe o RulesTestEnvironment uma vez para toda a
// suíte, limpa o Firestore entre casos e derruba a conexão no final.
// https://mochajs.org/#root-hook-plugins

import { env, setupTestEnv, teardownTestEnv } from './helpers';

export const mochaHooks = {
  async beforeAll(): Promise<void> {
    await setupTestEnv();
  },

  async afterEach(): Promise<void> {
    await env().clearFirestore();
  },

  async afterAll(): Promise<void> {
    await teardownTestEnv();
  },
};
