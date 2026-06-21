export function range(start, stop, step) {
  if (stop === undefined) {
    stop = start;
    start = 0;
  }

  if (step === undefined) step = start < stop ? 1 : -1;

  if (step === 0) throw new Error("range() step argument must not be zero");

  const length =
    step > 0
      ? Math.max(0, Math.ceil((stop - start) / step))
      : Math.max(0, Math.ceil((start - stop) / -step));
  const values = new Array(length);

  for (let index = 0, value = start; index < length; index++, value += step)
    values[index] = value;

  return values;
}
