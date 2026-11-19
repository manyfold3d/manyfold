import { globalIgnores } from 'eslint/config'
import neostandard from 'neostandard'

const ignores = [
  'public/vite*/*',
  'coverage/*',
  'vendor/bundle/*'
]

export default [
  globalIgnores(ignores),
  ...neostandard({
    ts: true,
    ignores
  }),
  {
    rules: {
      'no-void': 'off' // gets confused with typescript void, it seems
    }
  }
]
