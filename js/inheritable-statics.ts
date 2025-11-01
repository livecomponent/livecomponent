// Stolen shamelessly from Stimulus
// See: https://github.com/hotwired/stimulus/blob/422eb81fa6496d7e24c3983c63e74f3530367cd3/src/core/inheritable_statics.ts

import { Constructor } from "./constructor"

export function read_inheritable_static_array_values<T, U = string>(constructor: Constructor<T>, property_name: string) {
  const ancestors = get_ancestors_for_constructor(constructor)
  return Array.from(
    ancestors.reduce((values, constructor) => {
      get_own_static_array_values(constructor, property_name).forEach((name) => values.add(name))
      return values
    }, new Set() as Set<U>)
  )
}

function get_ancestors_for_constructor<T>(constructor: Constructor<T>) {
  const ancestors: Constructor<any>[] = []
  while (constructor) {
    ancestors.push(constructor)
    constructor = Object.getPrototypeOf(constructor)
  }
  return ancestors.reverse()
}

function get_own_static_array_values<T>(constructor: Constructor<T>, property_name: string) {
  const definition = (constructor as any)[property_name]
  return Array.isArray(definition) ? definition : []
}
