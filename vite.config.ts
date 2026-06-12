import { defineConfig } from 'vite'
import Rails from 'vite-plugin-rails'
import wasm from 'vite-plugin-wasm'

export default defineConfig({
  plugins: [
    Rails(),
    wasm()
  ],
  css: {
    preprocessorOptions: {
      scss: {
        silenceDeprecations: ["import", "color-functions", "global-builtin", "if-function"]
      }
    }
  }
})
