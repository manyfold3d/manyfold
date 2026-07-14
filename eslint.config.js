import neostandard from 'neostandard'

export default [
  ...neostandard({
    ts: true,
    ignores: [
      'public/vite*/*',
      'coverage/*',
      'vendor/bundle/*'
    ]
  }),
  {
    rules: {
      'no-void': 'off' // gets confused with typescript void, it seems
    }
  }
]
