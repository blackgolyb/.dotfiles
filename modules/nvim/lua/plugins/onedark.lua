return {
    {
        "navarasu/onedark.nvim",
        priority = 1000,
        config = function()
            require('onedark').setup {
                style = 'darker',    -- Базовий стиль One Dark
                transparent = true,  -- Вмикаємо можливість прозорості

                -- Налаштовуємо стилі для стандартних груп
                code_style = {
                    comments = 'italic',
                    keywords = 'bold',    -- Робимо ключові слова (if, return) жирними
                    functions = 'none',   -- Прибираємо курсив або жирність з функцій
                    strings = 'none',
                    variables = 'none',
                },

                -- Ручне керування кольорами (Highlights)
                highlights = {
                    -- 1. Скидаємо все в стандартний колір тексту (Onedark White)
                    ["@variable"] = { fg = '$fg' },
                    ["@function"] = { fg = '$fg' },
                    ["@method"] = { fg = '$fg' },
                    ["@property"] = { fg = '$fg' },
                    ["@parameter"] = { fg = '$fg' },

                    -- 2. Ключові слова: колір як у тексту, але жирний
                    ["@keyword"] = { fg = '$fg', fmt = 'bold' },
                    ["@keyword.function"] = { fg = '$fg', fmt = 'bold' }, -- 'func' або 'function'
                    ["@keyword.return"] = { fg = '$fg', fmt = 'bold' },
                    ["@repeat"] = { fg = '$fg', fmt = 'bold' },          -- for, while
                    ["@conditional"] = { fg = '$fg', fmt = 'bold' },     -- if, else

                    -- 3. Залишаємо колір тільки для даних (Рядки та Числа)
                    ["@string"] = { fg = '$green' },      -- Рядки будуть зеленими (класика One Dark)
                    ["@number"] = { fg = '$orange' },     -- Числа — помаранчевими
                    ["@boolean"] = { fg = '$orange' },    -- true/false теж як числа
                    ["@constant"] = { fg = '$orange' },   -- Константи

                    -- Бонус: колір коментарів (зазвичай їх роблять тьмяними)
                    ["@comment"] = { fg = '$grey', fmt = 'italic' },
                }
            }
            require('onedark').load()
        end
    },
}
