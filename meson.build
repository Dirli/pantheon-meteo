project('io.elementary.meteo', ['vala', 'c'], version: '0.1.0')

gnome = import('gnome')

asresources = gnome.compile_resources(
    'as-resources', join_paths('data', meson.project_name() + '.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

subdir('data')
subdir('src')

meson.add_install_script('meson/post_install.py')
