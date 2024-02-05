local pickState = 0

local paths = vim.api.nvim_list_runtime_paths()
local optsPath = string.format('%s\\plugin\\coloroptions.txt', paths[#paths])

local setColor = function(win, buf, colors)
    return function()
        local cursor = vim.api.nvim_win_get_cursor(win)

        local mode = 'w+'
        if pickState == 1 then
            mode = 'a+'
        end

        local file = io.open(optsPath, mode)

        if file then
            if pickState == 0 then
                vim.cmd(string.format('colorscheme %s', colors[cursor[1]]))
                file:write(colors[cursor[1]], "\n")
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "enable transparency", "disable transparency" })
                pickState = 1
            else
                pickState = 0

                if cursor[1] == 1 then
                    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
                    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
                    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
                    vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
                    file:write("en\n")
                else
                    file:write("dis\n")
                end

                vim.api.nvim_win_close(win, true)
                vim.api.nvim_buf_delete(buf, { force = true })
            end

            file:close()
        end
    end
end

ColorPicker = function()
    local ui = vim.api.nvim_list_uis()[1]
    pickState = 0

    local opts = {
        relative = 'editor',
        width = 30,
        height = 30,
        col = (ui.width / 2) - 15,
        row = (ui.height / 2) - 15,
        anchor = 'NW',
        style = 'minimal',
        border = 'rounded'
    }

    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, 1, opts)

    local color_files = vim.api.nvim_get_runtime_file('colors/*.vim', true)
    local lua_color_files = vim.api.nvim_get_runtime_file('colors/*.lua', true)
    local colors = {}

    table.move(lua_color_files, 1, #lua_color_files, #color_files + 1, color_files)

    for _, v in ipairs(color_files) do
        local j = 0
        if not string.match(v, 'runtime') then -- exclude default
            for i = string.len(v), 1, -1 do
                if string.char(v:byte(i)) == '\\' then
                    j = i + 1
                    goto continue
                end
            end
            ::continue::
            table.insert(colors, string.sub(v, j, string.len(v) - 4))
        end
    end

    vim.api.nvim_buf_set_lines(buf, 0, #colors + 1, false, colors)
    vim.api.nvim_buf_set_keymap(buf, 'n', '<C-s>', '', { callback = setColor(win, buf, colors) }) -- didn't work when I was using arch, worked fine on windows 10
end

vim.keymap.set('n', '<C-c>', ColorPicker, {})
