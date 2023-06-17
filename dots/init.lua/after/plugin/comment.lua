require("Comment").setup(
{
        toggler = {
                ---Line-comment toggle keymap
                line = '<leader>/',
                ---Block-comment toggle keymap
                block = 'gbc',
        },
        opleader = {
                ---Line-comment keymap
                line = '<leader>/',
                ---Block-comment keymap
                block = 'gb',
        },
})
