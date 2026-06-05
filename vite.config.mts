import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'

export default defineConfig({
  server: {
    cors: true
  },
  plugins: [
    RubyPlugin(),
  ],
})
