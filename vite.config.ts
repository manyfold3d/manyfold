import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import wasm from 'vite-plugin-wasm'

export default defineConfig({
  plugins: [
    RubyPlugin(),
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
