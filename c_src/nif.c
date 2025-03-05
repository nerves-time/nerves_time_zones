// SPDX-FileCopyrightText: 2021 Frank Hunleth
//
// SPDX-License-Identifier: Apache-2.0
//
#include <erl_nif.h>

#include <stdlib.h>
#include <time.h>

static ERL_NIF_TERM tz_set(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    char value[256];

    if (!enif_get_string(env, argv[0], value, sizeof(value), ERL_NIF_LATIN1))
        return enif_make_badarg(env);

    setenv("TZ", value, 1);
    tzset();

    return enif_make_atom(env, "ok");
}

static ErlNifFunc nif_funcs[] =
{
    {"set", 1, tz_set, 0}
};

ERL_NIF_INIT(Elixir.NervesTimeZones.Nif, nif_funcs, NULL, NULL, NULL, NULL)
