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

export type RubySymbolHash<T extends Record<string, any>> = {
  _lc_symhash: true
} & T

export type RubyHashWithIndifferentAccess<T extends Record<string, any>> = RubyHash<T> & {
  _lc_hwia: true;
}

export const Ruby = {
  make_symbol: (value: string): RubySymbol => {
    return {value, _lc_sym: true};
  },

  make_hash: <T extends Record<string, any>>(): RubyHash<T> => {
    return {_lc_symkeys: []} as RubyHash<T>;
  },

  make_symbol_hash: <T extends Record<string, any>>(): RubySymbolHash<T> => {
    return {_lc_symhash: true} as RubySymbolHash<T>;
  },

  make_hash_with_indifferent_access: <T extends Record<string, any>>(): RubyHashWithIndifferentAccess<T> => {
    return {_lc_symkeys: [], _lc_hwia: true} as RubyHashWithIndifferentAccess<T>;
  },

  hash_set<T extends Record<string, any>, K extends keyof T & string>(
    hash: RubyHash<T> | RubySymbolHash<T> | RubyHashWithIndifferentAccess<T>,
    key: K | RubySymbol,
    value: T[K]
  ) {
    const isSymbol = typeof key === 'object' && '_lc_sym' in key;
    const actualKey = isSymbol ? key.value : key;

    if (isSymbol && "_lc_symkeys" in hash) {
      hash._lc_symkeys.push(actualKey as K);
    }

    (hash as T)[actualKey as K] = value;
  },

  hash_set_symbol<T extends Record<string, any>, K extends keyof T & string>(
    hash: RubyHash<T> | RubySymbolHash<T> | RubyHashWithIndifferentAccess<T>,
    key: K,
    value: T[K]
  ) {
    if ("_lc_symkeys" in hash) {
      hash._lc_symkeys.push(key);
    }

    (hash as T)[key] = value;
  },

  hash_get<T extends Record<string, any>, K extends keyof T & string>(
    hash: RubyHash<T> | RubySymbolHash<T> | RubyHashWithIndifferentAccess<T>,
    key: K | RubySymbol
  ) {
    const actualKey = typeof key === 'object' && '_lc_sym' in key ? key.value : key;
    return hash[actualKey as K];
  },

  hash_delete<T extends Record<string, any>, K extends keyof T & string>(
    hash: RubyHash<T> | RubySymbolHash<T> | RubyHashWithIndifferentAccess<T>,
    key: K | RubySymbol
  ) {
    const actualKey = typeof key === 'object' && '_lc_sym' in key ? key.value : key;

    if ("_lc_symkeys" in hash) {
      const index = hash._lc_symkeys.indexOf(actualKey);

      if (index > -1) {
        hash._lc_symkeys.splice(index, 1);
      }
    }

    delete hash[actualKey as K];
  },

  object_to_hash<T>(object: T): RubyHash<T> {
    return {_lc_symkeys: [], ...object};
  },

  object_to_symbol_hash<T>(object: T): RubySymbolHash<T> {
    return {_lc_symhash: true, ...object};
  }
}
