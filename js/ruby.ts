export type RubySymbol = {
  value: string;
  _lc_sym: true;
}

export type RecordProxy<T> = {
  _lc_ar: {
    gid: string;
    signed: boolean;
  }
} & T

export type RubyGlobalID = {
  _lc_gid: string;
}

export type RubyHash<T extends Record<string, any>> = {
  _lc_symkeys: Array<string>;
} & T

export type RubyKwargs<T extends Record<string, any>> = {
  _lc_kwargs: Array<string>
} & T

export type RubyHashWithIndifferentAccess<T extends Record<string, any>> = RubyHash<T> & {
  _lc_hwia: true;
}

export const Ruby = {
  make_symbol: (value: string): RubySymbol => {
    return { value, _lc_sym: true };
  },

  hash_set<T extends Record<string, any>, K extends keyof T & string>(
    hash: RubyHash<T> | RubyKwargs<T> | RubyHashWithIndifferentAccess<T>,
    key: K,
    value: T[K]
  ) {
    if ("_lc_kwargs" in hash) {
      hash._lc_kwargs.push(key);
    }

    (hash as T)[key] = value;
  },

  hash_set_symbol<T extends Record<string, any>, K extends keyof T & string>(
    hash: RubyHash<T> | RubyKwargs<T> | RubyHashWithIndifferentAccess<T>,
    key: K,
    value: T[K]
  ) {
    if ("_lc_kwargs" in hash) {
      hash._lc_kwargs.push(key);
    } else if ("_lc_symkeys" in hash) {
      hash._lc_symkeys.push(key);
    }

    (hash as T)[key] = value;
  },

  hash_get<T extends Record<string, any>, K extends keyof T & string>(
    hash: RubyHash<T> | RubyKwargs<T> | RubyHashWithIndifferentAccess<T>,
    key: K
  ) {
    return hash[key];
  },

  hash_delete<T extends Record<string, any>, K extends keyof T & string>(
    hash: RubyHash<T> | RubyKwargs<T> | RubyHashWithIndifferentAccess<T>,
    key: K
  ) {
    if ("_lc_kwargs" in hash || "_lc_symkeys" in hash) {
      const keys = hash._lc_kwargs || hash._lc_symkeys;
      const index = keys.indexOf(key);

      if (index > -1) {
        keys.splice(index, 1);
      }
    }

    delete hash[key];
  },
}
