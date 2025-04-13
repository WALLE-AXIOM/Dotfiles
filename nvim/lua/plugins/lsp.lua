return {
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v4.x',
        lazy = false,
        config = false,
        init = function()
            -- Disable automatic setup, we are doing it manually
            vim.g.lsp_zero_extend_cmp = 0
            vim.g.lsp_zero_extend_lspconfig = 0
        end,
    },
    {
        'williamboman/mason.nvim',
        lazy = false,
        config = true,
    },

    -- LSP
    {
        'neovim/nvim-lspconfig',
        cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = {
            { 'williamboman/mason-lspconfig.nvim' },
        },
        opts = {
            inlay_hint = { enable = true },
        },
        config = function()
            vim.g.diagnostics_on = false
            local notify = require('notify')
            -- function to toggle "normal" diagnostics or lsp-lines diagnostics.
            local function toggle_diagnostics()
                vim.g.diagnostics_on = not vim.g.diagnostics_on
                if vim.g.diagnostics_on then
                    vim.diagnostic.config({
                        virtual_lines = {
                            severity = {
                                min = "ERROR",
                            }
                        },

                    })
                    notify("Warnings disabled")
                else
                    vim.diagnostic.config({
                        virtual_lines = {
                            severity = {
                                min = "HINT",
                            }
                        },
                    })
                    notify("Warnings enabled")
                end
            end


            -- This is where all the LSP shenanigans will live
            local lsp_zero = require('lsp-zero')

            local attach = function(_, bufnr)
                local opts = { buffer = bufnr, remap = false }
                vim.lsp.inlay_hint.enable(true, nil)

                vim.keymap.set("n", "<Leader>tw", toggle_diagnostics,
                    { desc = "Toggle Warnings", buffer = bufnr, remap = false })
                vim.keymap.set("n", "<leader>s", function() vim.lsp.buf.format() end, opts)
                vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
                vim.keymap.set("n", "<Leader>d", '<cmd>Telescope lsp_document_symbols<cr>', opts)
                vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
                vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
                vim.keymap.set("n", "<leader>ca", function() vim.lsp.buf.code_action() end,
                    { buffer = bufnr, remap = false, desc = "code_action" })
                vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end,
                    { buffer = bufnr, remap = false, desc = "rename" })
                vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
            end

            local capabilities = require('blink.cmp').get_lsp_capabilities()
            lsp_zero.extend_lspconfig({
                lsp_attach = attach,
                capabilities = capabilities,
            })

            local lspc = require('lspconfig')

            require('flutter-tools').setup({
                lsp = {
                    capabilities = capabilities,
                    on_attach = function(client, bufnr)
                        vim.bo.tabstop = 2
                        vim.bo.shiftwidth = 2
                        vim.bo.expandtab = true
                        vim.bo.softtabstop = 2
                        attach(client, bufnr)
                    end,
                },
            })

            require('mason-lspconfig').setup({
                ensure_installed = {
                    'rust_analyzer',
                    'clangd',
                    'lua_ls',
                },
                handlers = {
                    lsp_zero.default_setup,
                    lua_ls = function()
                        local lua_opts = lsp_zero.nvim_lua_ls({
                            settings = {
                                Lua = {
                                    hint = { enable = true }
                                }
                            }
                        })
                        lspc.lua_ls.setup(lua_opts)
                    end,
                    ts_ls = function()
                        local vue_language_server_path = require("mason-registry").get_package("vue-language-server")
                            :get_install_path() .. "/node_modules/@vue/language-server"
                        lspc.ts_ls.setup({
                            init_options = {
                                plugins = {
                                    {
                                        name = '@vue/typescript-plugin',
                                        location = vue_language_server_path,
                                        languages = { 'vue' },
                                    },
                                },
                            },
                            capabilities = capabilities,
                            settings = {
                                typescript = {
                                    tsserver = {
                                        useSyntaxServer = false,
                                    },
                                    inlayHints = {
                                        includeInlayParameterNameHints = 'all',
                                        includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                                        includeInlayFunctionParameterTypeHints = true,
                                        includeInlayVariableTypeHints = true,
                                        includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                                        includeInlayPropertyDeclarationTypeHints = true,
                                        includeInlayFunctionLikeReturnTypeHints = true,
                                        includeInlayEnumMemberValueHints = true,
                                    },
                                },
                            },
                        })
                    end,
                    html = function()
                        lspc.html.setup({
                            capabilities = capabilities,
                        })
                    end,
                    eslint = function()
                        lspc.eslint.setup({
                            root_dir = function()
                                return vim.fn.getcwd();
                            end,
                            capabilities = capabilities,
                        })
                    end,
                    rust_analyzer = function()
                        vim.g.rustacean = {
                            server = {
                                capabilities = capabilities,
                                on_attach = function(client, bufnr)
                                    client.cancel_request = function(_, _)
                                    end
                                    attach(client, bufnr);
                                end
                            }
                        }
                    end,
                    clangd = function()
                        lspc.clangd.setup({
                            on_attach = function(c, b)
                                local opts = { buffer = b, remap = false, desc = "Switch Source Header" }
                                vim.keymap.set("n", "<Leader>r", function() vim.cmd('ClangdSwitchSourceHeader') end, opts)
                                attach(c, b)
                            end,
                            capabilities = capabilities,
                        })
                    end,
                    gopls = function()
                        lspc.gopls.setup({
                            on_attach = function(c, b)
                                attach(c, b)
                            end,
                            capabilities = capabilities,
                            settings = {
                                gopls = {
                                    hints = {
                                        assignVariableTypes = true,
                                        compositeLiteralFields = true,
                                        compositeLiteralTypes = true,
                                        constantValues = true,
                                        functionTypeParameters = true,
                                        parameterNames = true,
                                        rangeVariableTypes = true,
                                    },
                                },
                            },
                            root_dir = function()
                                return vim.fn.getcwd()
                            end,
                        })
                    end,
                    glsl_analyzer = function()
                        lspc.glsl_analyzer.setup({
                            capabilities = capabilities,
                            on_attach = function(client, buffer)
                                client.cancel_request = function(_, _)
                                end
                                attach(client, buffer);
                            end,
                        })
                    end,
                    hls = function()
                        local ht = require('haskell-tools')
                        local bufnr = vim.api.nvim_get_current_buf()
                        local opts = { noremap = true, silent = true, buffer = bufnr, }
                        -- haskell-language-server relies heavily on codeLenses,
                        -- so auto-refresh (see advanced configuration) is enabled by default
                        vim.keymap.set('n', '<leader>cl', vim.lsp.codelens.run, opts)
                        -- Hoogle search for the type signature of the definition under the cursor
                        vim.keymap.set('n', '<leader>hs', ht.hoogle.hoogle_signature, opts)
                        -- Evaluate all code snippets
                        vim.keymap.set('n', '<leader>ea', ht.lsp.buf_eval_all, opts)
                        -- Toggle a GHCi repl for the current package
                        vim.keymap.set('n', '<leader>rr', ht.repl.toggle, opts)
                        -- Toggle a GHCi repl for the current buffer
                        vim.keymap.set('n', '<leader>rf', function()
                            ht.repl.toggle(vim.api.nvim_buf_get_name(0))
                        end, opts)
                        vim.keymap.set('n', '<leader>rq', ht.repl.quit, opts)
                    end
                }
            })
        end
    }
}
