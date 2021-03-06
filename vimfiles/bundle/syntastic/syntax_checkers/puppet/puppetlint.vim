"============================================================================
"File:        puppet.vim
"Description: Syntax checking plugin for syntastic.vim
"Maintainer:  Eivind Uggedal <eivind at uggedal dot com>
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================

if exists("g:loaded_syntastic_puppet_puppetlint_checker")
    finish
endif
let g:loaded_syntastic_puppet_puppetlint_checker=1

function! SyntaxCheckers_puppet_puppetlint_IsAvailable()
    return executable("puppet-lint")
endfunction

if !exists("g:syntastic_puppet_validate_disable")
    let g:syntastic_puppet_validate_disable = 0
endif

if !exists("g:syntastic_puppet_lint_disable")
    let g:syntastic_puppet_lint_disable = 0
endif

if !executable("puppet-lint")
    let g:syntastic_puppet_lint_disable = 1
endif

function! s:PuppetVersion()
    if !exists("s:puppet_version")
        let s:puppet_version = syntastic#util#parseVersion("puppet --version 2>" . syntastic#util#DevNull())
    endif
    return s:puppet_version
endfunction

function! s:PuppetLintVersion()
    if !exists("s:puppet_lint_version")
        let s:puppet_lint_version = syntastic#util#parseVersion("puppet-lint --version 2>" . syntastic#util#DevNull())
    endif
    return s:puppet_lint_version
endfunction

if !g:syntastic_puppet_lint_disable
    if !syntastic#util#versionIsAtLeast(s:PuppetLintVersion(), [0,1,10])
        let g:syntastic_puppet_lint_disable = 1
    endif
end

function! s:getPuppetLintErrors()
    if !exists("g:syntastic_puppet_lint_arguments")
        let g:syntastic_puppet_lint_arguments = ''
    endif

    let makeprg = 'puppet-lint --log-format "\%{KIND} [\%{check}] \%{message} at \%{fullpath}:\%{linenumber}" '.g:syntastic_puppet_lint_arguments.' '.shellescape(expand('%'))
    let errorformat = '%t%*[a-zA-Z] %m at %f:%l'
    return SyntasticMake({ 'makeprg': makeprg, 'errorformat': errorformat, 'subtype': 'Style' })
endfunction

function! s:getPuppetMakeprg()
    "If puppet is >= version 2.7 then use the new executable
    if syntastic#util#versionIsAtLeast(s:PuppetVersion(), [2,7,0])
        let makeprg = 'puppet parser validate ' .
                    \ shellescape(expand('%')) .
                    \ ' --color=false'
    else
        let makeprg = 'puppet --color=false --parseonly '.shellescape(expand('%'))
    endif
    return makeprg
endfunction

function! s:getPuppetEfm()
    "some versions of puppet (e.g. 2.7.10) output the message below if there
    "are any syntax errors
    let errorformat = '%-Gerr: Try ''puppet help parser validate'' for usage,'
    let errorformat .= 'err: Could not parse for environment %*[a-z]: %m at %f:%l'

    "Puppet 3.0.0 changes this from "err:" to "Error:"
    "reset errorformat in that case
    if syntastic#util#versionIsAtLeast(s:PuppetVersion(), [3,0,0])
        let errorformat = '%-GError: Try ''puppet help parser validate'' for usage,'
        let errorformat .= 'Error: Could not parse for environment %*[a-z]: %m at %f:%l'
    endif

    return errorformat
endfunction

function! SyntaxCheckers_puppet_puppetlint_GetLocList()
    let errors = []

    if !g:syntastic_puppet_validate_disable
        let errors = errors + SyntasticMake({ 'makeprg': s:getPuppetMakeprg(), 'errorformat': s:getPuppetEfm() })
    endif

    if !g:syntastic_puppet_lint_disable
        let errors = errors + s:getPuppetLintErrors()
    endif

    return errors
endfunction

call g:SyntasticRegistry.CreateAndRegisterChecker({
    \ 'filetype': 'puppet',
    \ 'name': 'puppetlint'})
