import { defineConfig } from 'vite'
import Rails from 'vite-plugin-rails'

export default defineConfig({
  plugins: [
    Rails(),
  ],
  css: {
    preprocessorOptions: {
      scss: {
        silenceDeprecations: ["import", "color-functions", "global-builtin", "if-function"]
      }
    }
  }
})
