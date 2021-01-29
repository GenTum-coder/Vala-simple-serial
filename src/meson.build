vala_terminal_sources = [
  'main.vala',
  'window.vala',
  'port.c',
]

vala_terminal_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
#  dependency('gee-0.8', version: '>= 0.18'),
  meson.get_compiler('vala').find_library('posix'),
]

gnome = import('gnome')

vala_terminal_sources += gnome.compile_resources('vala_terminal-resources',
  'vala_terminal.gresource.xml',
  c_name: 'vala_terminal'
)

executable('vala-terminal', vala_terminal_sources,
  vala_args: '--target-glib=2.50',  dependencies: vala_terminal_deps,
  install: true,
)
