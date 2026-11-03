import { describe, it } from "node:test";
import assert from "node:assert/strict";

export { describe, it };
export function expect(actual: any) {
  return {
    toBe: (v: unknown) => assert.equal(actual, v),
    toEqual: (v: unknown) => assert.deepEqual(actual, v),
    toContain: (v: string) => assert.ok(String(actual).includes(v), `expected to contain ${v}`),
    toMatchObject: (v: Record<string, unknown>) => { for (const k of Object.keys(v)) assert.deepEqual(actual[k], v[k]); },
    toBeCloseTo: (v: number, d = 2) => assert.ok(Math.abs(actual - v) < 10 ** -d / 2),
  };
}
