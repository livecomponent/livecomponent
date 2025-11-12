import { Ruby } from "ruby";
import { describe, it, expect } from "vitest";

describe("Ruby", () => {
  describe("make_symbol", () => {
    it("creates a new symbol", () => {
      expect(Ruby.make_symbol("foo")).toStrictEqual({_lc_sym: true, value: "foo"});
    });
  });

  describe("make_hash", () => {
    it("creates a new hash", () => {
      expect(Ruby.make_hash()).toStrictEqual({_lc_symkeys: []});
    });
  });

  describe("make_symbol_hash", () => {
    it("creates a new hash with all symbol keys", () => {
      expect(Ruby.make_symbol_hash()).toStrictEqual({_lc_symhash: true});
    });
  });

  describe("make_hash_with_indifferent_access", () => {
    it("creates a new hash with indifferent access", () => {
      expect(Ruby.make_hash_with_indifferent_access()).toStrictEqual({_lc_symkeys: [], _lc_hwia: true});
    });
  });

  describe("hash_set", () => {
    it("adds a key/value pair", () => {
      const hash = Ruby.make_hash<{foo: string}>();
      Ruby.hash_set(hash, "foo", "bar");
      expect(hash._lc_symkeys).not.toContain("foo");
      expect(hash.foo).toBe("bar");
    });

    it("adds a key/value pair using a RubySymbol as the key", () => {
      const hash = Ruby.make_hash<{foo: string}>();
      const symbol = Ruby.make_symbol("foo");
      Ruby.hash_set(hash, symbol, "bar");
      expect(hash.foo).toBe("bar");
      expect(hash._lc_symkeys).toContain("foo");
    });

    it("adds a key/value pair to a symbol hash", () => {
      const hash = Ruby.make_symbol_hash<{foo: string}>();
      Ruby.hash_set(hash, "foo", "bar");
      expect(hash.foo).toBe("bar");
    });

    it("adds a key/value pair to a symbol hash using a RubySymbol as the key", () => {
      const hash = Ruby.make_symbol_hash<{foo: string}>();
      const symbol = Ruby.make_symbol("foo");
      Ruby.hash_set(hash, symbol, "bar");
      expect(hash.foo).toBe("bar");
    });

    it("adds a key/value pair to a hash with indifferent access", () => {
      const hash = Ruby.make_hash_with_indifferent_access<{foo: string}>();
      Ruby.hash_set(hash, "foo", "bar");
      expect(hash._lc_symkeys).not.toContain("foo");
      expect(hash.foo).toBe("bar");
    });

    it("adds a key/value pair to a hash with indifferent access using a RubySymbol as the key", () => {
      const hash = Ruby.make_hash_with_indifferent_access<{foo: string}>();
      const symbol = Ruby.make_symbol("foo");
      Ruby.hash_set(hash, symbol, "bar");
      expect(hash.foo).toBe("bar");
      expect(hash._lc_symkeys).toContain("foo");
    });
  });

  describe("hash_set_symbol", () => {
    it("adds a key/value pair, treating the key as a symbol", () => {
      const hash = Ruby.make_hash<{foo: string}>();
      Ruby.hash_set_symbol(hash, "foo", "bar");
      expect(hash.foo).toBe("bar");
      expect(hash._lc_symkeys).toContain("foo");
    });

    it("adds a key/value pair to a symbol hash, treating the key as a symbol", () => {
      const hash = Ruby.make_symbol_hash<{foo: string}>();
      Ruby.hash_set_symbol(hash, "foo", "bar");
      expect(hash.foo).toBe("bar");
    });

    it("adds a key/value pair to a symbol with indifferent access, treating the key as a symbol", () => {
      const hash = Ruby.make_symbol_hash<{foo: string}>();
      Ruby.hash_set_symbol(hash, "foo", "bar");
      expect(hash.foo).toBe("bar");
    });
  });

  describe("hash_get", () => {
    it("gets the value for the key", () => {
      const hash = Ruby.make_hash();
      Ruby.hash_set(hash, "foo", "bar");
      expect(Ruby.hash_get(hash, "foo")).toBe("bar");
    });

    it("gets the value for the symbol key", () => {
      const hash = Ruby.make_hash();
      Ruby.hash_set_symbol(hash, "foo", "bar");
      expect(Ruby.hash_get(hash, "foo")).toBe("bar");
    });

    it("gets the value using a RubySymbol as the key", () => {
      const hash = Ruby.make_hash();
      Ruby.hash_set_symbol(hash, "foo", "bar");
      const symbol = Ruby.make_symbol("foo");
      expect(Ruby.hash_get(hash, symbol)).toBe("bar");
    });

    it("returns undefined if the key doesn't exist in the hash", () => {
      const hash = Ruby.make_hash();
      expect(Ruby.hash_get(hash, "foo")).toBe(undefined);
    });
  });

  describe("hash_delete", () => {
    it("deletes the value for the key", () => {
      const hash = Ruby.make_hash();
      Ruby.hash_set(hash, "foo", "bar");
      expect(Ruby.hash_get(hash, "foo")).toBe("bar");
      expect(hash.foo).toBe("bar");
      Ruby.hash_delete(hash, "foo");
      expect(Ruby.hash_get(hash, "foo")).toBe(undefined);
      expect(hash.foo).toBe(undefined);
    });

    it("deletes the value for the key when the key is a RubySymbol", () => {
      const hash = Ruby.make_hash();
      Ruby.hash_set_symbol(hash, "foo", "bar");
      expect(Ruby.hash_get(hash, "foo")).toBe("bar");
      const symbol = Ruby.make_symbol("foo");
      Ruby.hash_delete(hash, symbol);
      expect(Ruby.hash_get(hash, "foo")).toBe(undefined);
      expect(hash.foo).toBe(undefined);
      expect(hash._lc_symkeys).not.toContain("foo");
    });
  });

  describe("object_to_hash", () => {
    it("converts the given object into a RubyHash", () => {
      const hash = Ruby.object_to_hash({foo: "bar"});
      expect(hash).toStrictEqual({_lc_symkeys: [], foo: "bar"});
    });
  });

  describe("object_to_symbol_hash", () => {
    it("converts the given object into a RubySymbolHash", () => {
      const hash = Ruby.object_to_symbol_hash({foo: "bar"});
      expect(hash).toStrictEqual({_lc_symhash: true, foo: "bar"});
    });
  });
});
