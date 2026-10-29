// SPDX-FileCopyrightText: 2021 Frank Hunleth
//
// SPDX-License-Identifier: Apache-2.0
//
#include <erl_nif.h>

#include <limits.h>
#include <stdlib.h>
#include <time.h>

static ERL_NIF_TERM tz_set(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
    unsigned int length;

    if (!enif_get_list_length(env, argv[0], &length) || length >= PATH_MAX)
        return enif_make_badarg(env);

    char *value = enif_alloc(length + 1);
    if (!value)
        return enif_make_badarg(env);

    if (enif_get_string(env, argv[0], value, length + 1, ERL_NIF_LATIN1) <= 0) {
        enif_free(value);
        return enif_make_badarg(env);
    }

    setenv("TZ", value, 1);
    enif_free(value);
    tzset();

    return enif_make_atom(env, "ok");
}

static ErlNifFunc nif_funcs[] =
{
    {"set", 1, tz_set, 0}
};

ERL_NIF_INIT(Elixir.NervesTimeZones.Nif, nif_funcs, NULL, NULL, NULL, NULL)
