import { dirname, extname, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"
import dts from "vite-plugin-dts"

const __dirname = dirname(fileURLToPath(import.meta.url))

const addJavaScriptExtensions = (content) =>
  content.replace(
    /(\bfrom\s+["']|\bimport\(\s*["'])(\.{1,2}\/[^"']+)(["'])/g,
    (match, prefix, specifier, suffix) =>
      extname(specifier) ? match : `${prefix}${specifier}.js${suffix}`
  )

export default defineConfig({
  root: __dirname,
  build: {
    sourcemap: true,
    lib: {
      entry: {
        "live-component": resolve(__dirname, "index.ts"),
        "react": resolve(__dirname, "react.ts"),
      },
      formats: ["es", "cjs"],
      fileName: (format, entryName) =>
        format === "es" ? `${entryName}.js` : `${entryName}.cjs`,
    },
    minify: "terser",
    target: "es2020",
    rollupOptions: {
      // make sure to externalize deps that shouldn"t be bundled
      // into your library
      external: [
        "@hotwired/stimulus",
        "react",
        "react-dom",
        "react-dom/client",
        "react/jsx-runtime"
      ],
    },
  },
  plugins: [dts({
    tsconfigPath: "./tsconfig.json",
    exclude: ["**/*.test.ts", "smoke", "test-helpers", "vitest.setup.ts", "vitest.config.ts"],
    beforeWriteFile: (_filePath, content) => ({
      content: addJavaScriptExtensions(content),
    }),
  })],
})
