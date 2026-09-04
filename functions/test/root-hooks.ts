// Root hook plugin do Mocha: importa `src/index` uma única vez (dispara
// `admin.initializeApp()`, que só pode rodar uma vez por processo) e limpa
// Firestore/Auth emulator entre casos. https://mochajs.org/#root-hook-plugins

import '../src/index';
import {clearAuth, clearFirestore} from './helpers';

export const mochaHooks = {
  async afterEach(): Promise<void> {
    await clearFirestore();
    await clearAuth();
  },
};
