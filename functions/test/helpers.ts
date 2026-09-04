// Utilidades compartilhadas pelos testes das Cloud Functions. Diferente de
// `test/rules/` (que testa `firestore.rules` via `@firebase/rules-unit-testing`
// com contextos autenticados), aqui o Admin SDK real - o mesmo que as
// functions usam em produção - fala direto com os emuladores Firestore/Auth,
// e cada handler é chamado diretamente (não via um trigger disparado de
// verdade). Ver docs/21_BACKLOG_ACHADOS_TECNICOS.md, item 4, para o porquê.

// Precisa bater com o --project em package.json e o alias "default" do
// .firebaserc: em singleProjectMode, um id diferente gera um aviso
// "Multiple projectIds" no log do emulador.
export const PROJECT_ID = 'elytron-d2b-dev';

const FIRESTORE_EMULATOR_URL = 'http://127.0.0.1:8080';
const AUTH_EMULATOR_URL = 'http://127.0.0.1:9099';

/** Apaga todos os documentos do Firestore emulator entre casos de teste. */
export async function clearFirestore(): Promise<void> {
  await fetch(
    `${FIRESTORE_EMULATOR_URL}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`,
    {method: 'DELETE'}
  );
}

/** Apaga todas as contas do Auth emulator entre casos de teste. */
export async function clearAuth(): Promise<void> {
  await fetch(
    `${AUTH_EMULATOR_URL}/emulator/v1/projects/${PROJECT_ID}/accounts`,
    {method: 'DELETE'}
  );
}

/**
 * Monta um `CallableRequest` mínimo para chamar um handler `onCall` direto,
 * sem passar por um cliente de verdade nem mintar token. Os handlers só
 * leem `data` e `auth`; `rawRequest`/`acceptsStreaming` não são usados por
 * nenhuma das functions deste projeto.
 */
export function makeCallableRequest<T>(
  data: T,
  auth?: {uid: string; token: Record<string, unknown>}
): any {
  return {
    data,
    auth,
    rawRequest: {} as unknown,
    acceptsStreaming: false,
  };
}

/**
 * Monta um evento de `onDocumentWritten` mínimo para chamar o handler
 * direto - só `params` e `data.before/after.data()` são lidos pelas
 * functions deste projeto.
 */
export function makeFirestoreEvent<Params extends Record<string, string>>(
  params: Params,
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined
): any {
  return {
    params,
    data: {
      before: before === undefined ? undefined : {data: () => before},
      after: after === undefined ? undefined : {data: () => after},
    },
  };
}
