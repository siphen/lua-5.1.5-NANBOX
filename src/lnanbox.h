/*
** NaN-box access helpers
** Stage 1: classic TValue pass-through + Stage 2 scaffolding constants.
** These inline helpers centralize TValue reads/writes so a future
** NaN-box representation can be enabled under LUA_NANBOX without
** touching call sites.
*/

#ifndef lnanbox_h
#define lnanbox_h

#include "llimits.h"
 #include "lua.h"
#include <stdint.h>
#include <string.h>

/* Stage 2: Suggested bit layout (little-endian, IEEE-754) */
#if defined(LUA_NANBOX_LAYOUT)
/*  quiet NaN pattern and masks */
#define NB_QNAN      0x7ff8000000000000ULL
#define NB_EXPMSK    0x7ff0000000000000ULL
#define NB_SIGMSK    0x000fffffffffffffULL
/* Use fraction bits 50..49 for tag; 48..0 for payload (49 bits) */
#define NB_TAG_SHIFT 49
#define NB_TAG_MASK  (((uint64_t)0x3ULL) << NB_TAG_SHIFT)
#define NB_PAY_MASK  ((1ULL<<NB_TAG_SHIFT) - 1ULL)

/* tag values proposal (keep <= 7 for 3 bits) */
#define NB_TAG_IMM     1  /* imm: payload 0=nil,1=false,2=true */
#define NB_TAG_LUD     2  /* light userdata */
#define NB_TAG_GC      3  /* collectable; subtype from GC header */

/* helpers */
static inline int nb_isnanbox_u(uint64_t u){ return (u & NB_EXPMSK) == NB_EXPMSK && (u & NB_SIGMSK); }
static inline uint64_t nb_pack_tag_imm(uint64_t imm){ return NB_QNAN | ((NB_TAG_IMM & 0x3ULL) << NB_TAG_SHIFT) | (imm & NB_PAY_MASK); }

#if defined(LUA_NANBOX_STRICT)
#include <stdio.h>
#include <stdlib.h>
static inline void nb_assert_ptr(uintptr_t p){ if ((p & ~NB_PAY_MASK) && (((p >> 47) & 1ULL) != ((p >> 48) & 1ULL))) { fputs("[nanbox] pointer out of range/canonicality\n", stderr); abort(); } }
#else
static inline void nb_assert_ptr(uintptr_t p){ (void)p; }
#endif

static inline uint64_t nb_pack_tag_ptr(uint64_t tag, uintptr_t p){ nb_assert_ptr(p); return NB_QNAN | ((tag & 0x3ULL) << NB_TAG_SHIFT) | (NB_PAY_MASK & (uint64_t)p); }
static inline uintptr_t nb_payload(uint64_t u){ return (uintptr_t)(u & NB_PAY_MASK); }
static inline uintptr_t nb_unbox_ptr(uint64_t u){ uintptr_t p = nb_payload(u); if (p & (1ULL<<47)) p |= ~NB_PAY_MASK; return p; }
static inline uint64_t nb_make_nil(void){ return nb_pack_tag_imm(0); }
#endif

/* Forward declaration: TValue is defined in lobject.h before including this */
/* Pass-through helpers for classic TValue layout */

/* Bitcast helpers to avoid aliasing UB */
static inline uint64_t tv_d2u(lua_Number d) { uint64_t u; memcpy(&u, &d, sizeof u); return u; }
static inline lua_Number tv_u2d(uint64_t u) { lua_Number d; memcpy(&d, &u, sizeof d); return d; }

#if defined(LUA_NANBOX_LAYOUT)
/* Encode/decode using single 64-bit box (numbers: non-NaN doubles). */
static inline int tv_type(const TValue *o) {
  uint64_t u = o->box.u;
  /* Non-NaN or Inf => number */
  if ((u & NB_EXPMSK) != NB_EXPMSK) return LUA_TNUMBER;
  /* Distinguish boxed-NaN from arithmetic NaN: only our tag values are boxed */
  uint64_t t = (u & NB_TAG_MASK) >> NB_TAG_SHIFT;
  if (t != NB_TAG_IMM && t != NB_TAG_LUD && t != NB_TAG_GC) {
    return LUA_TNUMBER; /* arithmetic NaN treated as number */
  }
  switch (t) {
    case NB_TAG_IMM: {
      uint64_t imm = u & NB_PAY_MASK;
      if (imm == 0) return LUA_TNIL;
      if (imm == 1) return LUA_TBOOLEAN;
      if (imm == 2) return LUA_TBOOLEAN;
      return LUA_TNONE;
    }
    case NB_TAG_LUD: return LUA_TLIGHTUSERDATA;
    case NB_TAG_GC: {
      uintptr_t p = (uintptr_t)(u & NB_PAY_MASK);
      if (p == 0) return LUA_TDEADKEY; /* special immediate encoding */
      const struct GCheader *h = (const struct GCheader *)p;
      return h->tt;
    }
    default: return LUA_TNONE;
  }
}
static inline int tv_iscollectable(const TValue *o) { int tt = tv_type(o); return tt >= LUA_TSTRING; }
static inline GCObject *tv_getgc(const TValue *o) { return (GCObject*)nb_unbox_ptr(o->box.u); }
static inline void     *tv_getp (const TValue *o) { return (void*)nb_unbox_ptr(o->box.u); }
static inline lua_Number tv_getn(const TValue *o) { return o->box.n; }
static inline int        tv_getb(const TValue *o) { return (tv_type(o) == LUA_TBOOLEAN) && ((o->box.u & NB_PAY_MASK) == 2); }

/* Fast-path number test: boxed only when exponent==all-ones, sig!=0, and tag matches ours */
static inline int tv_isboxed(uint64_t u){
  if ((u & NB_EXPMSK) != NB_EXPMSK) return 0;              /* finite -> number */
  if ((u & NB_SIGMSK) == 0) return 0;                      /* inf -> number */
  uint64_t t = (u & NB_TAG_MASK) >> NB_TAG_SHIFT;
  return (t == NB_TAG_IMM || t == NB_TAG_LUD || t == NB_TAG_GC);
}
static inline int tv_isnumber_fast(const TValue *o){ return !tv_isboxed(o->box.u); }

static inline void tv_settype(TValue *o, int tt) {
  /* Only used in debug checks; synthesize a tag */
  switch (tt) {
    case LUA_TNIL: o->box.u = nb_pack_tag_imm(0); break;
    case LUA_TBOOLEAN: o->box.u = nb_pack_tag_imm(1); break; /* false */
    case LUA_TLIGHTUSERDATA: o->box.u = nb_pack_tag_ptr(NB_TAG_LUD, 0); break;
    case LUA_TNUMBER: o->box.n = 0.0; break;
    case LUA_TDEADKEY: {
      /* preserve existing pointer payload so findindex can match dead keys */
      uintptr_t p = nb_unbox_ptr(o->box.u);
      o->box.u = nb_pack_tag_ptr(NB_TAG_GC, p);
      break;
    }
    default: /* generic collectable null */ o->box.u = nb_pack_tag_ptr(NB_TAG_GC, 0); break;
  }
}
static inline void tv_setnil (TValue *o) { o->box.u = nb_pack_tag_imm(0); }
static inline void tv_setn   (TValue *o, lua_Number x) { o->box.n = x; }
static inline void tv_setp   (TValue *o, void *p) { o->box.u = nb_pack_tag_ptr(NB_TAG_LUD, (uintptr_t)p); }
static inline void tv_setb   (TValue *o, int b) { o->box.u = nb_pack_tag_imm(b ? 2 : 1); }
static inline void tv_setgc  (TValue *o, GCObject *gco, int tag) {
  (void)tag; /* subtype read from GC header */
  o->box.u = nb_pack_tag_ptr(NB_TAG_GC, (uintptr_t)gco);
}
static inline void tv_copy   (TValue *dst, const TValue *src) { dst->box.u = src->box.u; }

#else
/* Classic layout pass-through */
static inline int tv_type(const TValue *o) { return o->tt; }
static inline int tv_iscollectable(const TValue *o) { return tv_type(o) >= LUA_TSTRING; }
static inline GCObject *tv_getgc(const TValue *o) { return o->value.gc; }
static inline void     *tv_getp (const TValue *o) { return o->value.p; }
static inline lua_Number tv_getn(const TValue *o) { return o->value.n; }
static inline int        tv_getb(const TValue *o) { return o->value.b; }
static inline void tv_settype(TValue *o, int tt) { o->tt = tt; }
static inline void tv_setnil (TValue *o) { o->tt = LUA_TNIL; }
static inline void tv_setn   (TValue *o, lua_Number x) { o->value.n = x; o->tt = LUA_TNUMBER; }
static inline void tv_setp   (TValue *o, void *p) { o->value.p = p; o->tt = LUA_TLIGHTUSERDATA; }
static inline void tv_setb   (TValue *o, int b) { o->value.b = b; o->tt = LUA_TBOOLEAN; }
static inline void tv_setgc  (TValue *o, GCObject *gco, int tag) { o->value.gc = gco; o->tt = tag; }
static inline void tv_copy   (TValue *dst, const TValue *src) { dst->value = src->value; dst->tt = src->tt; }
#endif

#endif /* lnanbox_h */
