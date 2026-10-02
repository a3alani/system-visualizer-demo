export function createCheckout({ charge, createOrder }) {
  const requests = new Map();
  return function checkout({ idempotencyKey, ...input }) {
    if (!idempotencyKey) return Promise.reject(new Error('idempotencyKey is required'));
    if (requests.has(idempotencyKey)) return requests.get(idempotencyKey);
    const attempt = Promise.resolve().then(async () => {
      const payment = await charge(input);
      const order = await createOrder({ ...input, payment });
      return { payment, order };
    }).catch((error) => {
      requests.delete(idempotencyKey);
      throw error;
    });
    requests.set(idempotencyKey, attempt);
    return attempt;
  };
}
