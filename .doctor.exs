%Doctor.Config{
  ignore_modules: [Aurora.Uix.Web.Templates.Base, Aurora.Uix.Web.Gettext, Aurora.Uix.Web.Uix.DataConfigUI, Aurora.Uix.ResourceRegistration],
  ignore_paths: [~r".+/-local-.*"],
  min_module_doc_coverage: 100,
  min_module_spec_coverage: 100,
  min_overall_doc_coverage: 100,
  min_overall_moduledoc_coverage: 100,
  min_overall_spec_coverage: 100,
  exception_moduledoc_required: true,
  raise: true,
  reporter: Doctor.Reporters.Full,
  struct_type_spec_required: true,
  umbrella: false,
  failed: true
}
