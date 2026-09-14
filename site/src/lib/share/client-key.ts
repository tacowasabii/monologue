const HEX_GROUP = /^[0-9a-fA-F]{1,4}$/;

/**
 * Expand a (possibly "::"-compressed) IPv6 address into its 8 hextets, each
 * padded to 4 lowercase hex digits. Returns null if the address doesn't look
 * like valid IPv6 — the caller falls back to treating it as an opaque key.
 */
function expandIPv6(address: string): string[] | null {
  const segments = address.split('::');
  if (segments.length > 2) return null; // more than one "::" is not valid IPv6

  let head: string[];
  let tail: string[];
  if (segments.length === 2) {
    head = segments[0] === '' ? [] : segments[0].split(':');
    tail = segments[1] === '' ? [] : segments[1].split(':');
  } else {
    head = segments[0].split(':');
    tail = [];
  }
  if (head.some((h) => h === '') || tail.some((h) => h === '')) return null;

  const missing = 8 - head.length - tail.length;
  if (segments.length === 1) {
    if (head.length !== 8) return null;
  } else if (missing < 0) {
    return null;
  }
  const zeros = segments.length === 2 ? Array<string>(missing).fill('0') : [];
  const full = [...head, ...zeros, ...tail];
  if (full.length !== 8 || !full.every((h) => HEX_GROUP.test(h))) return null;
  return full.map((h) => h.padStart(4, '0').toLowerCase());
}

/**
 * Normalize a rate-limit client key so rotating addresses within the same
 * IPv6 /64 (a single residential/mobile allocation, and trivial for a client
 * to rotate through) can't bypass the per-client upload limit. IPv4
 * addresses — and anything that doesn't parse as IPv6 — pass through
 * unchanged.
 */
export function normalizeClientKey(key: string): string {
  if (!key.includes(':')) return key;
  const expanded = expandIPv6(key);
  if (!expanded) return key;
  return `${expanded.slice(0, 4).join(':')}::/64`;
}
