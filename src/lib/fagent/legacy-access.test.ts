import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const sql = readFileSync(new URL("../../../drizzle/migrations/0000_restrict_retired_catch_table_access.sql", import.meta.url), "utf8");

for (const table of ["places", "spawns"]) {
  test(`retired ${table} blocks public access while retaining server access and records`, () => {
    assert.ok(sql.includes(`ALTER TABLE public.${table} ENABLE ROW LEVEL SECURITY;`));
    assert.ok(sql.includes(`ALTER POLICY "${table} are publicly readable" ON public.${table} USING (false);`));
    assert.match(sql, /REVOKE ALL PRIVILEGES ON TABLE public\.places, public\.spawns FROM PUBLIC, anon, authenticated;/);
    assert.match(sql, /GRANT ALL PRIVILEGES ON TABLE public\.places, public\.spawns TO service_role;/);
    assert.doesNotMatch(sql, /\b(?:DROP\s+TABLE|TRUNCATE|DELETE\s+FROM)\b/i);
  });
}