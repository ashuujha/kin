import {describe,it,expect} from 'vitest';
import {captureLink,isExpired,hashToken} from '../src/sharing';
import {safePhone} from '../src/ui';

describe('receiver boundaries',()=>{
  it('accepts only explicit paths and 256-bit URL-safe tokens',()=>{
    expect(captureLink({pathname:'/s',hash:'#'+'a'.repeat(43)})).toEqual({kind:'s',token:'a'.repeat(43)});
    expect(captureLink({pathname:'/e',hash:'#'+'b'.repeat(43)})?.kind).toBe('e');
    for (const pathname of ['/','/evil','/s/extra']) expect(captureLink({pathname,hash:'#'+'a'.repeat(43)})).toBeNull();
    expect(captureLink({pathname:'/s',hash:'#abc'})).toBeNull();
  });
  it('fails closed on missing, invalid and exactly expired deadlines',()=>{
    const now=Date.parse('2026-10-09T10:00:00Z');
    expect(isExpired(undefined,now)).toBe(true);expect(isExpired('bad',now)).toBe(true);
    expect(isExpired('2026-10-09T10:00:00Z',now)).toBe(true);
    expect(isExpired('2026-10-09T10:00:01Z',now)).toBe(false);
  });
  it('hashes secrets before the medical RPC',async()=>{
    expect(await hashToken('a'.repeat(43))).toMatch(/^[a-f0-9]{64}$/);
    await expect(hashToken('invalid')).rejects.toThrow();
  });
  it('rejects unsafe telephone URLs',()=>{
    expect(safePhone('+91 (999) 123-4567')).toBe('+919991234567');
    expect(safePhone('javascript:alert(1)')).toBeNull();
  });
});
