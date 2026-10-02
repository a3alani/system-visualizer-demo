import test from 'node:test';
import assert from 'node:assert/strict';
import { createCheckout } from './checkout.mjs';

const request = { idempotencyKey: 'cart-42', amount: 2500 };
function fixture() {
  const calls = { charge: 0, order: 0 };
  const checkout = createCheckout({
    charge: async () => ({ id: `payment-${++calls.charge}` }),
    createOrder: async () => ({ id: `order-${++calls.order}` }),
  });
  return { checkout, calls };
}

test('a sequential retry reuses the completed result', async () => {
  const { checkout, calls } = fixture();
  const first = await checkout(request);
  assert.strictEqual(await checkout(request), first);
  assert.deepEqual(calls, { charge: 1, order: 1 });
});

test('concurrent retries share one in-flight checkout', async () => {
  const { checkout, calls } = fixture();
  const first = checkout(request);
  const second = checkout(request);
  assert.strictEqual(first, second);
  const results = await Promise.all([first, second, checkout(request)]);
  assert.ok(results.every((result) => result === results[0]));
  assert.deepEqual(calls, { charge: 1, order: 1 });
});

test('different keys create independent payments and orders', async () => {
  const { checkout, calls } = fixture();
  await Promise.all([checkout(request), checkout({ ...request, idempotencyKey: 'cart-43' })]);
  assert.deepEqual(calls, { charge: 2, order: 2 });
});

test('a rejected payment clears the key so a later retry can succeed', async () => {
  let attempts = 0;
  let orders = 0;
  const checkout = createCheckout({
    charge: async () => {
      if (++attempts === 1) throw new Error('provider unavailable');
      return { id: 'payment-1' };
    },
    createOrder: async () => ({ id: `order-${++orders}` }),
  });
  await assert.rejects(checkout(request), /provider unavailable/);
  const result = await checkout(request);
  assert.equal(result.order.id, 'order-1');
  assert.equal(attempts, 2);
  assert.equal(orders, 1);
});
