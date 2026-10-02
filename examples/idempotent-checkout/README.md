# Idempotent checkout: a small PR-to-video example

A client can retry checkout after a timeout. Without deduplication, each request
can charge the customer again and create another order.

`createCheckout` remembers a promise by `idempotencyKey`. A matching request
shares the in-flight work or receives the same completed result. A rejected
attempt removes the key, allowing another attempt. Different keys work independently.

Run the dependency-free tests with Node.js:

```sh
node --test examples/idempotent-checkout/*.test.mjs
```

This is an educational, process-local store. Keys disappear on restart, are not
shared between servers, and have no expiry. Callers must reuse a key only for the
same payload. It does not validate key/payload conflicts or provide durable payment
idempotency. If charging succeeds but order creation fails, a retry can charge
again. A real checkout also needs provider idempotency, durable state, recovery,
and a retention policy; this example demonstrates only request deduplication.
