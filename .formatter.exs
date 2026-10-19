# Used by "mix format"
locals_without_parens = [
  auix_resource_metadata: 1,
  auix_resource_metadata: 2,
  field: 1,
  field: 2,
  fields: 1,
  fields: 2,
  upload: 0,
  upload: 1
]

[
  import_deps: [:ash],
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  inputs: [
    "{mix,.formatter}.exs",
    ".doctor.exs",
    "{config,lib,test}/**/*.{ex,exs}",
    "priv/repo/**/*.exs"
  ]
]
