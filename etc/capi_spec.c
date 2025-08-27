/* Simple C API unit test for Lua 5.1 + NaN-box layout */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static int add1(lua_State *L) {
  double x = lua_tonumber(L, 1);
  lua_pushnumber(L, x + 1);
  return 1;
}

static void check(int cond, const char *msg) {
  if (!cond) {
    fprintf(stderr, "[capi] FAIL: %s\n", msg);
    /* force a crash-like exit to catch in scripts */
    *(volatile int *)0 = 0;
  }
}

int main(void) {
  lua_State *L = luaL_newstate();
  check(L != NULL, "luaL_newstate");
  luaL_openlibs(L);

  /* nil, boolean, number */
  lua_pushnil(L);
  check(lua_type(L, -1) == LUA_TNIL, "nil type");
  lua_pop(L, 1);

  lua_pushboolean(L, 1);
  check(lua_type(L, -1) == LUA_TBOOLEAN && lua_toboolean(L, -1) == 1, "boolean true");
  lua_pop(L, 1);

  lua_pushnumber(L, 3.5);
  check(lua_type(L, -1) == LUA_TNUMBER && (lua_tonumber(L, -1) > 3.49 && lua_tonumber(L, -1) < 3.51), "number roundtrip");
  lua_pop(L, 1);

  /* string */
  lua_pushstring(L, "hello");
  size_t len = 0; const char *s = lua_tolstring(L, -1, &len);
  check(lua_type(L, -1) == LUA_TSTRING && s && len == 5 && strcmp(s, "hello") == 0, "string roundtrip");
  lua_pop(L, 1);

  /* lightuserdata */
  static int anchor;
  void *p = &anchor;
  lua_pushlightuserdata(L, p);
  void *p2 = lua_touserdata(L, -1);
  const void *po = lua_topointer(L, -1);
  check(lua_type(L, -1) == LUA_TLIGHTUSERDATA && p2 == p && po == p, "lightuserdata roundtrip");
  lua_pop(L, 1);

  /* lightuserdata: NULL pointer */
  lua_pushlightuserdata(L, NULL);
  check(lua_type(L, -1) == LUA_TLIGHTUSERDATA && lua_touserdata(L, -1) == NULL && lua_topointer(L, -1) == NULL, "lightuserdata NULL");
  lua_pop(L, 1);

  /* lightuserdata: heap pointer and table key roundtrip */
  void *hp = malloc(64);
  check(hp != NULL, "malloc");
  lua_newtable(L);              /* tbl */
  lua_pushlightuserdata(L, hp); /* key */
  lua_pushstring(L, "heap");   /* val */
  lua_settable(L, -3);
  lua_pushlightuserdata(L, hp);
  lua_gettable(L, -2);
  size_t lhp=0; const char *svh = lua_tolstring(L, -1, &lhp);
  check(lhp==4 && svh && strcmp(svh, "heap")==0, "lightuserdata table key");
  lua_pop(L, 2); /* pop val and tbl */
  free(hp);

  /* full userdata */
  void *ud = lua_newuserdata(L, 32);
  check(lua_type(L, -1) == LUA_TUSERDATA && ud == lua_touserdata(L, -1) && lua_topointer(L, -1) == ud, "userdata alloc");
  lua_pop(L, 1);

  /* table set/get (string and integer keys) */
  lua_newtable(L);
  lua_pushstring(L, "x"); lua_pushnumber(L, 42); lua_settable(L, -3);
  lua_pushnumber(L, 1); lua_pushstring(L, "v"); lua_settable(L, -3);
  /* table topointer identity (same object reference) */
  const void *tptr1 = lua_topointer(L, -1);
  lua_pushvalue(L, -1); /* duplicate table */
  const void *tptr2 = lua_topointer(L, -1);
  check(tptr1 == tptr2, "table topointer identity");
  lua_pop(L, 1);
  lua_pushstring(L, "x"); lua_gettable(L, -2);
  check(lua_type(L, -1) == LUA_TNUMBER && lua_tonumber(L, -1) == 42, "table string key");
  lua_pop(L, 1);
  lua_pushnumber(L, 1); lua_gettable(L, -2);
  size_t l2=0; const char *sv = lua_tolstring(L, -1, &l2);
  check(lua_type(L, -1) == LUA_TSTRING && l2 == 1 && sv && sv[0]=='v', "table int key");
  lua_pop(L, 2); /* pop value and table */

  /* lua_topointer for strings: identical for same interned string */
  lua_pushstring(L, "idstr"); const void *s1 = lua_topointer(L, -1); lua_pop(L, 1);
  lua_pushstring(L, "idstr"); const void *s2 = lua_topointer(L, -1); lua_pop(L, 1);
  check(s1 == s2, "string topointer identity");

  /* function topointer identity (same closure reference) */
  lua_pushcfunction(L, add1);
  const void *f1 = lua_topointer(L, -1);
  lua_pushvalue(L, -1);
  const void *f2 = lua_topointer(L, -1);
  check(f1 == f2, "function topointer identity with same ref");
  lua_pop(L, 2);

  /* thread topointer identity */
  lua_State *T2 = lua_newthread(L);
  const void *th1 = lua_topointer(L, -1);
  lua_pushvalue(L, -1);
  const void *th2 = lua_topointer(L, -1);
  check(th1 == th2, "thread topointer identity with same ref");
  lua_pop(L, 2);

  /* xmove roundtrip for table and lightuserdata */
  lua_State *T3 = lua_newthread(L);
  check(T3 != NULL, "newthread for xmove");
  lua_newtable(L); /* obj1 */
  void *plu = &anchor; /* reuse anchor */
  lua_pushlightuserdata(L, plu); /* obj2 */
  const void *tab_before = lua_topointer(L, -2);
  const void *lu_before = lua_topointer(L, -1);
  lua_xmove(L, T3, 2); /* move 2 values to T3 */
  const void *lu_after = lua_topointer(T3, -1);
  const void *tab_after = lua_topointer(T3, -2);
  check(tab_before == tab_after, "xmove table identity");
  check(lu_before == lu_after, "xmove lightuserdata identity");
  lua_pop(T3, 2);

  /* xmove for interned string and C function */
  lua_pushstring(L, "xmove_idstr");
  lua_pushcfunction(L, add1);
  const void *s_before = lua_topointer(L, -2);
  const void *cf_before = lua_topointer(L, -1);
  lua_xmove(L, T3, 2);
  const void *cf_after = lua_topointer(T3, -1);
  const void *s_after = lua_topointer(T3, -2);
  check(s_before == s_after, "xmove string identity");
  check(cf_before == cf_after, "xmove cfunction identity");
  lua_pop(T3, 2);

  /* C function call */
  lua_pushcfunction(L, add1);
  lua_pushnumber(L, 9);
  check(lua_pcall(L, 1, 1, 0) == 0, "pcall add1");
  check(lua_tonumber(L, -1) == 10, "add1 result");
  lua_pop(L, 1);

  /* coroutine/thread basic check */
  lua_State *T = lua_newthread(L);
  check(T != NULL, "lua_newthread");
  lua_pop(L, 1);

  lua_close(L);
  puts("[capi] OK");
  return 0;
}
