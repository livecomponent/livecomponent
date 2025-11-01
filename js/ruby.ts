export type RubySymbol = {
  value: string
}

// class RubyHash {
//   private symbol_keys: Set<string>;

//   constructor(public hash: {[key: string]: any}) {
//     this.symbol_keys = new Set(hash["_aj_symbol_keys"] || []);
//   }

//   get(key: string) {
//     return this.hash[key];
//   }

//   set(key: string, value: any) {
//     this.hash[key] = value;
//     this.symbol_keys.add(key);
//   }

//   to_h() {
//     return {...this.hash, "_aj_symbol_keys": Array.from(this.symbol_keys)};
//   }
// }
