authenticate :user do
  mount ActionDispatch::Static.new(
    Rails.application,
    Rails.root.join("vendor/kiri_moto").to_s
  ), at: "/applications/kiri", as: "kirimoto"

  mount ActionDispatch::Static.new(
    Rails.application,
    Rails.root.join("vendor/kiri_moto/wasm").to_s
  ), at: "/wasm"

  mount ActionDispatch::Static.new(
    Rails.application,
    Rails.root.join("vendor/kiri_moto/wasm").to_s
  ), at: "/lib/kiri/wasm"

  mount ActionDispatch::Static.new(
    Rails.application,
    Rails.root.join("vendor/kiri_moto/run").to_s
  ), at: "/lib/kiri/run"
end
