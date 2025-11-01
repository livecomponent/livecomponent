import { dirname, resolve } from "node:path"
import { fileURLToPath } from "node:url"
import { defineConfig } from "vite"
import dts from "vite-plugin-dts"

const __dirname = dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  root: __dirname,
  build: {
    sourcemap: true,
    lib: {
      entry: resolve(__dirname, "index.ts"),
      name: "live-component",
      fileName: "live-component",
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
      output: {
        // Provide global variables to use in the UMD build
        // for externalized deps
        globals: {
          "@hotwired/stimulus": "Stimulus",
          "react": "React",
          "react-dom": "ReactDOM",
          "react/jsx-runtime": "React",
          "react-dom/client": "ReactDOM",
        },
      },
    },
  },
  plugins: [dts({
    rollupTypes: true,
    tsconfigPath: "./tsconfig.json"
  })],
})