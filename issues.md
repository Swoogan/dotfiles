# Stow

* add stowrc
* add init
* add directory structure


# Neovim

## Features

* Add auto command to load dotnet compiler for cs files
* Prettier (done)
    * add format on save
* snippets
* Dispatch
    * dotnet run output
    * dotnet test output
* no way to copy file in nested folder
    :execute 'saveas' expand("%:h") . "/<new name>"
* no way to create file in nested folder
    :execute 'edit' expand("%:h") . "/<new name>"
* macro for Test_Method_Casing
* better textsitter incremental selection key mappings
* switch leader to <space>?

## Bugs

* omnisharp puts ^M in unix files
* omnisharp doesn't have go to implementation
* omnisharp doesn't have go to type declaration
* textsitter incremental selection key mappings don't seem to work with <leader>
* namespace custom mapping in TS textobjects doesn't work
