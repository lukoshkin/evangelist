// Configure CodeMirror Keymap
require([
  'nbextensions/vim_binding/vim_binding',   // depends your installation
], function() {
  // Map jj to <Esc>
  CodeMirror.Vim.map("jj", "<Esc>", "insert");
});

// Configure Jupyter Keymap
require([
  'nbextensions/vim_binding/vim_binding',
  'base/js/namespace',
], function(vim_binding, ns) {
  // Add post callback
  vim_binding.on_ready_callbacks.push(function(){
    var km = ns.keyboard_manager;
    // Indicate the key combination to run the commands
    km.edit_shortcuts.add_shortcut("Esc", CodeMirror.prototype.leaveNormalMode, true);
    km.edit_shortcuts.add_shortcut("alt-j", CodeMirror.prototype.leaveNormalMode, true);

    // Update help
    km.edit_shortcuts.events.trigger('rebuild.QuickHelp');
  });
});
