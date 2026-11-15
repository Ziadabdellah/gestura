import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, test } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  query,
  collection,
  where,
  setDoc,
  serverTimestamp,
} from 'firebase/firestore';

let env;

const now = () => Timestamp.now();

const text = { en: 'Hello', ar: 'مرحبًا', de: 'Hallo' };

const sign = (overrides = {}) => ({
  signLanguage: 'dgs',
  gloss: 'HELLO',
  meaning: text,
  category: 'greetings',
  video: 'media/dgs/hello/720.mp4',
  thumbnail: 'media/dgs/hello/thumb.webp',
  durationMs: 2400,
  source: { name: 'Deaf Signer', license: 'CC BY 4.0' },
  published: true,
  updatedAt: now(),
  ...overrides,
});

const progress = (overrides = {}) => ({
  bestScore: 90,
  completedAt: now(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const guest = () => env.authenticatedContext('guest', { firebase: { sign_in_provider: 'anonymous' } }).firestore();
const member = (uid, email, verified = true) =>
  env.authenticatedContext(uid, { email, email_verified: verified }).firestore();
const admin = () => member('admin-uid', 'admin@example.com');
const nobody = () => env.unauthenticatedContext().firestore();

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-gestura',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'admins/admin@example.com'), { addedAt: now() });
    await setDoc(doc(db, 'signs/hello'), sign());
    await setDoc(doc(db, 'signs/draft'), sign({ published: false }));
    await setDoc(doc(db, 'users/alice/progress/l1'), progress({ updatedAt: now() }));
  });
});

afterAll(() => env.cleanup());

describe('content', () => {
  test('signed-in learners read published content, guests included', async () => {
    await assertSucceeds(getDoc(doc(guest(), 'signs/hello')));
    await assertSucceeds(
      getDocs(query(collection(guest(), 'signs'), where('published', '==', true))),
    );
  });

  test('nobody reads content without signing in', async () => {
    await assertFails(getDoc(doc(nobody(), 'signs/hello')));
  });

  test('learners never see drafts, admins do', async () => {
    await assertFails(getDoc(doc(guest(), 'signs/draft')));
    await assertFails(getDocs(collection(guest(), 'signs')));
    await assertSucceeds(getDoc(doc(admin(), 'signs/draft')));
  });

  test('only a verified admin writes content', async () => {
    await assertFails(setDoc(doc(guest(), 'signs/new'), sign()));
    await assertFails(setDoc(doc(member('bob', 'bob@example.com'), 'signs/new'), sign()));
    await assertFails(
      setDoc(doc(member('admin-uid', 'admin@example.com', false), 'signs/new'), sign()),
    );
    await assertSucceeds(setDoc(doc(admin(), 'signs/new'), sign()));
    await assertSucceeds(deleteDoc(doc(admin(), 'signs/new')));
  });

  test('content must keep its shape', async () => {
    const db = admin();
    await assertFails(setDoc(doc(db, 'signs/bad'), sign({ extra: true })));
    await assertFails(setDoc(doc(db, 'signs/bad'), sign({ meaning: { de: 'Hallo' } })));
    await assertFails(setDoc(doc(db, 'signs/bad'), sign({ meaning: { en: 'Hi', it: 'Ciao' } })));
    await assertFails(setDoc(doc(db, 'signs/bad'), sign({ video: 'https://example.com/x.mp4' })));
    await assertFails(setDoc(doc(db, 'signs/bad'), sign({ durationMs: 0 })));
    await assertFails(
      setDoc(doc(db, 'signs/bad'), sign({ source: { name: 'X', license: 'Y', secret: 1 } })),
    );
    const { published, ...withoutPublished } = sign();
    await assertFails(setDoc(doc(db, 'signs/bad'), withoutPublished));
  });

  test('every content collection checks its own fields', async () => {
    const db = admin();
    await assertSucceeds(
      setDoc(doc(db, 'signLanguages/dgs'), {
        name: { en: 'German Sign Language', de: 'Deutsche Gebärdensprache' },
        fingerspelling: 'oneHanded',
        placeholder: false,
        order: 0,
        published: true,
        updatedAt: now(),
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, 'categories/greetings'), {
        signLanguage: 'dgs',
        name: { en: 'Greetings' },
        order: 0,
        published: true,
        updatedAt: now(),
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, 'courses/dgs-a1'), {
        signLanguage: 'dgs',
        level: 'a1',
        title: { en: 'First signs' },
        units: [{ index: 0, title: { en: 'Greetings' } }],
        order: 0,
        published: true,
        updatedAt: now(),
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, 'lessons/dgs-a1-1'), {
        courseId: 'dgs-a1',
        unit: 0,
        order: 0,
        title: { en: 'Hello' },
        steps: [{ type: 'learn', sign: 'hello' }],
        published: true,
        updatedAt: now(),
      }),
    );
    await assertFails(
      setDoc(doc(db, 'courses/bad'), {
        signLanguage: 'dgs',
        level: 'c2',
        title: { en: 'Too advanced' },
        units: [],
        order: 0,
        published: true,
        updatedAt: now(),
      }),
    );
  });
});

describe('admins', () => {
  test('people may only check their own admin entry', async () => {
    await assertSucceeds(getDoc(doc(admin(), 'admins/admin@example.com')));
    await assertFails(getDoc(doc(member('bob', 'bob@example.com'), 'admins/admin@example.com')));
    await assertFails(getDocs(collection(admin(), 'admins')));
  });

  test('nobody can make themselves an admin', async () => {
    await assertFails(setDoc(doc(member('bob', 'bob@example.com'), 'admins/bob@example.com'), {}));
    await assertFails(setDoc(doc(admin(), 'admins/bob@example.com'), {}));
  });
});

describe('progress', () => {
  test('a learner reads and writes their own progress', async () => {
    const db = member('alice', 'alice@example.com');
    await assertSucceeds(getDoc(doc(db, 'users/alice/progress/l1')));
    await assertSucceeds(setDoc(doc(db, 'users/alice/progress/l2'), progress()));
    await assertSucceeds(deleteDoc(doc(db, 'users/alice/progress/l2')));
  });

  test("nobody touches someone else's progress", async () => {
    const db = member('bob', 'bob@example.com');
    await assertFails(getDoc(doc(db, 'users/alice/progress/l1')));
    await assertFails(setDoc(doc(db, 'users/alice/progress/l9'), progress()));
    await assertFails(deleteDoc(doc(db, 'users/alice/progress/l1')));
  });

  test('progress keeps its shape', async () => {
    const db = member('alice', 'alice@example.com');
    const write = (data) => setDoc(doc(db, 'users/alice/progress/l3'), data);
    await assertFails(write(progress({ bestScore: 101 })));
    await assertFails(write(progress({ bestScore: 9.5 })));
    await assertFails(write(progress({ isAdmin: true })));
    await assertFails(write({ bestScore: 50, updatedAt: now() }));
    await assertFails(write(progress({ updatedAt: now() })));
    await assertFails(
      write(progress({ completedAt: Timestamp.fromMillis(Date.now() + 3 * 86400000) })),
    );
    await assertSucceeds(write(progress({ completedAt: Timestamp.fromMillis(0) })));
  });

  test('the user document itself is closed', async () => {
    await assertFails(setDoc(doc(member('alice', 'a@b.co'), 'users/alice'), { name: 'A' }));
    await assertFails(getDoc(doc(member('alice', 'a@b.co'), 'users/alice')));
  });
});
