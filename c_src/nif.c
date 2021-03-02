/*
 *  Copyright 2022 Frank Hunleth
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * nerves_time_zones NIF implementation.
 */

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
