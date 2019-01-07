project('io.elementary.meteo', ['vala', 'c'], version: '0.7.0')

gnome = import('gnome')
i18n = import('i18n')

asresources = gnome.compile_resources(
    'as-resources', join_paths('data', meson.project_name() + '.gresource.xml'),
    source_dir: 'data',
    c_name: 'as'
)

gio_dep = dependency('gio-2.0')
gobject_dep = dependency('gobject-2.0')
glib_dep = dependency('glib-2.0')
gio_unix_dep = dependency('gio-unix-2.0')
gtk_dep = dependency('gtk+-3.0')
libsoup_dep = dependency('libsoup-2.4')
json_dep = dependency('json-glib-1.0')
geocode_dep = dependency('geocode-glib-1.0')
granite_dep = dependency('granite')
dep_gweather = dependency('gweather-3.0')

# Make gettext work
add_project_arguments(
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    language:'c'
)

vala_args = []
if get_option('indicator')
    wingpanel_dep = dependency('wingpanel-2.0')
    vala_args += ['--define=INDICATOR_EXIST']
endif

subdir('data')
subdir('src')
subdir('po')

meson.add_install_script('meson/post_install.py')
