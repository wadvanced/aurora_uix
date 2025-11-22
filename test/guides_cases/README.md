# Notes regarding guides folder

## General purpose


This folder contains functional modules in order to be able to update the guides images in the documentation.

As with all media creation, some methodology is needed to ensure coherence among the produced items.

This document serve that purpose.

## Module creation

Any module can be created to fulfill the intended purpose, however it should comply with the following characteristics:

- `location` - Module should be located in folder 'test/guides_cases'
- `name` - Module should be prefixed with `Aurora.UixWeb.Guides.`
- `code` - Code can be anything, as long as it compiles and does not interfere with the test suite.
- `web` - For enabling web interaction with the module, it must be registered in the guide block in file
`test/app_web/router.exs`. - There are some helper macros in `Aurora.UixWeb.Test.RoutesHelper` module, which can aid into registering all the CRUD routes by using simple macros.

