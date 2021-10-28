# Stow

* revisit stow as it doesn't support `dot-` in subdirectories

# Neovim

## Features

* Prettier (done)
    * add format on save
* Dispatch
    * dotnet test output
* no way to create file in nested folder
    :execute 'edit' expand("%:h") . "/<new name>"
* macro for Test_Method_Casing
* better textsitter incremental selection key mappings
* switch leader to <space>?

## Bugs

* omnisharp puts ^M in unix files (just in the first using statement)
* omnisharp doesn't have go to implementation
* omnisharp doesn't have go to type declaration
* textsitter incremental selection key mappings don't seem to work with <leader>
* namespace custom mapping in TS textobjects doesn't work
