import { before, beforeEach, after, test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, updateDoc, collection, query, where, getDocs,
  runTransaction, Timestamp, serverTimestamp } from 'firebase/firestore';

let env;
const departure = Timestamp.fromDate(new Date(Date.now() + 86400000));
const verified = uid => env.authenticatedContext(uid, {email: `${uid}@greenfield.edu`, email_verified: true}).firestore();
const ride = (id = 'offer', ownerId = 'driver', overrides = {}) => ({
  id, ownerId, ownerName: 'Driver Student', ownerAvatar: '', originId: 'north_gate',
  destinationId: 'riverside_metro', kind: 'offer', departureAt: departure,
  dateKey: new Date(departure.toMillis()).toISOString().slice(0, 10),
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), totalSeats: 3,
  availableSeats: 3, contribution: 40, campusId: 'greenfield', vehicle: 'Honda City · Grey',
  note: '', active: true, matchedId: '', lastMatchId: '', ...overrides,
});
const match = (riderId = 'rider', overrides = {}) => ({
  id: `offer_${riderId}`, offerId: 'offer', requestId: '', driverId: 'driver',
  riderId, driverName: 'Driver Student', riderName: 'Rider Student', driverAvatar: '', riderAvatar: '',
  originId: 'north_gate', destinationId: 'riverside_metro', departureAt: departure,
  createdAt: serverTimestamp(), updatedAt: serverTimestamp(), seats: 1, contribution: 40,
  vehicle: 'Honda City · Grey', campusId: 'greenfield', status: 'confirmed',
  participants: ['driver', riderId], ...overrides,
});
async function seed() { await assertSucceeds(setDoc(doc(verified('driver'), 'rides/offer'), ride())); }
async function reserve(db, uid = 'rider') {
  return runTransaction(db, async tx => {
    const r = doc(db, 'rides/offer');
    const o = (await tx.get(r)).data();
    const m = match(uid);
    await tx.get(doc(db, `matches/${m.id}`));
    tx.set(doc(db, `matches/${m.id}`), m);
    tx.update(r, {availableSeats: o.availableSeats - 1, lastMatchId: m.id, updatedAt: serverTimestamp()});
  });
}
async function cancel(db, id = 'offer_rider', requestId = '') {
  return runTransaction(db, async tx => {
    const mp = doc(db, `matches/${id}`), op = doc(db, 'rides/offer');
    const m = (await tx.get(mp)).data(), o = (await tx.get(op)).data();
    const req = requestId ? (await tx.get(doc(db, `rides/${requestId}`))).data() : null;
    tx.update(mp, {status: 'cancelled', updatedAt: serverTimestamp()});
    tx.update(op, {availableSeats: o.availableSeats + m.seats, lastMatchId: id, updatedAt: serverTimestamp()});
    if (req) tx.update(doc(db, `rides/${requestId}`), {active: true,
      availableSeats: req.totalSeats, matchedId: '', updatedAt: serverTimestamp()});
  });
}
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-ridetogether',
    firestore: {host: '127.0.0.1', port: 8080, rules: readFileSync('../firestore.rules', 'utf8')}});
});
beforeEach(async () => { await env.clearFirestore(); });
after(async () => { await env.cleanup(); });

test('verified student can create a valid future ride; anonymous and unverified cannot', async () => {
  await seed();
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'rides/offer')));
  await assertFails(setDoc(doc(env.authenticatedContext('u', {email_verified: false}).firestore(), 'rides/u'), ride('u', 'u')));
});
test('rejects forged ownership, invalid endpoints, same route, past time and invalid seat counts', async () => {
  const db = verified('driver');
  for (const bad of [ride('bad', 'stranger'), ride('bad', 'driver', {originId: 'fake'}),
    ride('bad', 'driver', {destinationId: 'north_gate'}),
    ride('bad', 'driver', {departureAt: Timestamp.fromMillis(1)}),
    ride('bad', 'driver', {totalSeats: 7, availableSeats: 7}),
    ride('bad', 'driver', {availableSeats: 2}), ride('bad', 'driver', {contribution: -1})]) {
    await assertFails(setDoc(doc(db, 'rides/bad'), bad));
  }
});
test('rider reserves exactly one seat atomically; duplicate connection cannot consume another seat', async () => {
  await seed(); const db = verified('rider'); await assertSucceeds(reserve(db));
  assert.equal((await getDoc(doc(db, 'rides/offer'))).data().availableSeats, 2);
  await assertFails(reserve(db));
  assert.equal((await getDoc(doc(db, 'rides/offer'))).data().availableSeats, 2);
});
test('a match cannot be created without its seat reservation', async () => {
  await seed(); await assertFails(setDoc(doc(verified('rider'), 'matches/offer_rider'), match()));
});
test('neither drivers nor strangers can edit availability or route directly', async () => {
  await seed();
  await assertFails(updateDoc(doc(verified('driver'), 'rides/offer'), {availableSeats: 0}));
  await assertFails(updateDoc(doc(verified('stranger'), 'rides/offer'), {originId: 'central_library'}));
});
test('a driver cannot reserve a seat on behalf of an unrelated rider', async () => {
  await seed(); await assertFails(reserve(verified('driver'), 'rider'));
});
test('last-seat reservations prevent overbooking under concurrent joins', async () => {
  await setDoc(doc(verified('driver'), 'rides/offer'), ride('offer', 'driver', {totalSeats: 1, availableSeats: 1}));
  const results = await Promise.allSettled([reserve(verified('rider')), reserve(verified('rider2'), 'rider2')]);
  assert.equal(results.filter(x => x.status === 'fulfilled').length, 1);
  assert.equal((await getDoc(doc(verified('driver'), 'rides/offer'))).data().availableSeats, 0);
});
test('participant cancellation returns seats exactly once', async () => {
  await seed(); const db = verified('rider'); await reserve(db);
  await assertSucceeds(cancel(db));
  assert.equal((await getDoc(doc(db, 'rides/offer'))).data().availableSeats, 3);
  await assertFails(cancel(db));
});
test('strangers cannot read a match, send chat or impersonate a participant', async () => {
  await seed(); await reserve(verified('rider'));
  const stranger = verified('stranger');
  await assertFails(getDoc(doc(stranger, 'matches/offer_rider')));
  await assertFails(setDoc(doc(stranger, 'matches/offer_rider/messages/x'), {id: 'x', senderId: 'stranger', text: 'Hello', createdAt: serverTimestamp()}));
  await assertFails(setDoc(doc(verified('rider'), 'matches/offer_rider/messages/x'), {id: 'x', senderId: 'driver', text: 'Hello', createdAt: serverTimestamp()}));
});
test('participants can query their own matches and exchange immutable messages', async () => {
  await seed(); const db = verified('rider'); await reserve(db);
  const q = query(collection(db, 'matches'), where('participants', 'array-contains', 'rider'));
  await assertSucceeds(getDocs(q));
  await assertSucceeds(setDoc(doc(db, 'matches/offer_rider/messages/x'), {id: 'x', senderId: 'rider', text: 'At the gate!', createdAt: serverTimestamp()}));
  await assertSucceeds(getDoc(doc(verified('driver'), 'matches/offer_rider/messages/x')));
  await assertFails(updateDoc(doc(db, 'matches/offer_rider/messages/x'), {text: 'Edited'}));
});
test('cancelled chat is read-only and reservations cannot be reopened', async () => {
  await seed(); const db = verified('rider'); await reserve(db); await cancel(db);
  await assertFails(setDoc(doc(db, 'matches/offer_rider/messages/x'), {id: 'x', senderId: 'rider', text: 'Hi', createdAt: serverTimestamp()}));
  await assertFails(updateDoc(doc(db, 'matches/offer_rider'), {status: 'confirmed'}));
});
test('driver fulfils a compatible request, reserves all requested seats; cancellation reopens it', async () => {
  await seed();
  const request = ride('request', 'rider', {kind: 'request', ownerName: 'Rider Student', totalSeats: 2, availableSeats: 2, vehicle: ''});
  await assertSucceeds(setDoc(doc(verified('rider'), 'rides/request'), request));
  const db = verified('driver');
  await assertSucceeds(runTransaction(db, async tx => {
    await tx.get(doc(db, 'rides/offer')); await tx.get(doc(db, 'rides/request'));
    const m = match('rider', {seats: 2, requestId: 'request'});
    tx.set(doc(db, 'matches/offer_rider'), m);
    tx.update(doc(db, 'rides/offer'), {availableSeats: 1, lastMatchId: m.id, updatedAt: serverTimestamp()});
    tx.update(doc(db, 'rides/request'), {availableSeats: 0, active: false, matchedId: m.id, updatedAt: serverTimestamp()});
  }));
  assert.equal((await getDoc(doc(db, 'rides/request'))).data().active, false);
  await assertSucceeds(cancel(db, 'offer_rider', 'request'));
  assert.equal((await getDoc(doc(db, 'rides/request'))).data().active, true);
  assert.equal((await getDoc(doc(db, 'rides/offer'))).data().availableSeats, 3);
});
test('a request with a different route cannot be fulfilled', async () => {
  await seed();
  await setDoc(doc(verified('rider'), 'rides/request'), ride('request', 'rider', {kind: 'request', ownerName: 'Rider Student', destinationId: 'central_library', vehicle: ''}));
  const db = verified('driver');
  await assertFails(runTransaction(db, async tx => {
    await tx.get(doc(db, 'rides/offer')); await tx.get(doc(db, 'rides/request'));
    const m = match('rider', {requestId: 'request', seats: 3});
    tx.set(doc(db, 'matches/offer_rider'), m);
    tx.update(doc(db, 'rides/offer'), {availableSeats: 0, lastMatchId: m.id, updatedAt: serverTimestamp()});
    tx.update(doc(db, 'rides/request'), {availableSeats: 0, active: false, matchedId: m.id, updatedAt: serverTimestamp()});
  }));
});


test('rider may connect their own multi-seat request to an offer atomically', async () => {
  await seed();
  await setDoc(doc(verified('rider'), 'rides/request'), ride('request', 'rider', {
    kind: 'request', ownerName: 'Rider Student', totalSeats: 2, availableSeats: 2, vehicle: ''}));
  const db = verified('rider');
  await assertSucceeds(runTransaction(db, async tx => {
    await tx.get(doc(db, 'rides/offer')); await tx.get(doc(db, 'rides/request'));
    const m = match('rider', {requestId: 'request', seats: 2});
    tx.set(doc(db, 'matches/offer_rider'), m);
    tx.update(doc(db, 'rides/offer'), {availableSeats: 1, lastMatchId: m.id, updatedAt: serverTimestamp()});
    tx.update(doc(db, 'rides/request'), {availableSeats: 0, active: false, matchedId: m.id, updatedAt: serverTimestamp()});
  }));
  assert.equal((await getDoc(doc(db, 'rides/offer'))).data().availableSeats, 1);
});

test('a third party cannot connect someone else’s request', async () => {
  await seed();
  await setDoc(doc(verified('rider'), 'rides/request'), ride('request', 'rider', {
    kind: 'request', ownerName: 'Rider Student', vehicle: ''}));
  const db = verified('stranger');
  await assertFails(runTransaction(db, async tx => {
    await tx.get(doc(db, 'rides/offer')); await tx.get(doc(db, 'rides/request'));
    const m = match('rider', {requestId: 'request', seats: 3});
    tx.set(doc(db, 'matches/offer_rider'), m);
    tx.update(doc(db, 'rides/offer'), {availableSeats: 0, lastMatchId: m.id, updatedAt: serverTimestamp()});
    tx.update(doc(db, 'rides/request'), {availableSeats: 0, active: false, matchedId: m.id, updatedAt: serverTimestamp()});
  }));
});

test('transaction existence checks may read missing match IDs, but existing matches remain private', async () => {
  await seed();
  await assertSucceeds(getDoc(doc(verified('rider'), 'matches/offer_rider')));
  await assertSucceeds(getDoc(doc(verified('driver'), 'matches/offer_rider')));
  await reserve(verified('rider'));
  await assertFails(getDoc(doc(verified('stranger'), 'matches/offer_rider')));
});
