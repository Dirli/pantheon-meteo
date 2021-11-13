project (
  'io.elementary.meteo',
  ['vala', 'c'],
  version: '1.0.2'
)

gnome = import ('gnome')
i18n = import ('i18n')

asresources = gnome.compile_resources (
  'as-resources', join_paths ('data', meson.project_name () + '.gresource.xml'),
  source_dir: 'data',
  c_name: 'as'
)

# Make gettext work
add_project_arguments (
  '-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name ()),
  language: 'c'
)

conf_data = configuration_data ()
conf_data.set_quoted ('VERSION', meson.project_version ())
conf_data.set_quoted ('CONTACTS', 'litandrej85@gmail.com')
config_header = configure_file (
  input: 'src/config.vala.in',
  output: 'config.vala',
  configuration: conf_data
)

gweather_dep = dependency ('gweather-3.0')
if gweather_dep.version () >= '40.0'
  add_project_arguments ('--define=GWEATHER_40', language: 'vala')
endif

common_deps = [
  dependency ('gio-2.0'),
  dependency ('gobject-2.0'),
  dependency ('glib-2.0'),
  dependency ('gtk+-3.0'),
  dependency ('libsoup-2.4'),
  dependency ('json-glib-1.0'),
  gweather_dep,
  meson.get_compiler ('c').find_library ('m'),
  meson.get_compiler ('vala').find_library ('posix'),
]

app_deps = common_deps + [
  dependency ('granite'),
]

vala_args = []
if get_option ('geoclue')
  app_deps += dependency ('libgeoclue-2.0')
  vala_args += ['--define=GEOCLUE_EXIST']
endif

if get_option ('indicator')
  vala_args += ['--define=INDICATOR_EXIST']
endif

subdir ('data')
subdir ('po')

executable (
  meson.project_name (),
  'src/Constants.vala',
  'src/Enums.vala',
  'src/MainWindow.vala',
  'src/Meteo.vala',
  'src/Structs.vala',
  'src/Utils.vala',
  'src/Dialogs/About.vala',
  'src/Dialogs/Preferences.vala',
  'src/Providers/AbstractProvider.vala',
  'src/Providers/GWeatherProvider.vala',
  'src/Providers/OWMProvider.vala',
  'src/Services/Connector.vala',
  'src/Services/Geolocation.vala',
  'src/Services/SettingsWrapper.vala',
  'src/Views/DefaultPage.vala',
  'src/Views/WaitingPage.vala',
  'src/Views/WeatherPage.vala',
  'src/Widgets/Header.vala',
  asresources,
  config_header,
  vala_args: vala_args,
  c_args: [
    '-DGWEATHER_I_KNOW_THIS_IS_UNSTABLE',
  ],
  dependencies: app_deps,
  install : true
)

if get_option ('indicator')
  wingpanel_dep = dependency ('wingpanel')

  indicator_deps = common_deps + [
    dependency ('gio-unix-2.0'),
    wingpanel_dep
  ]

  shared_library (
    'meteo',
    'src/Indicator.vala',
    'src/Constants.vala',
    'src/Enums.vala',
    'src/Structs.vala',
    'src/Utils.vala',
    'src/Providers/AbstractProvider.vala',
    'src/Providers/GWeatherProvider.vala',
    'src/Providers/OWMProvider.vala',
    'src/Services/Connector.vala',
    'src/Services/SettingsWrapper.vala',
    'src/Widgets/Panel.vala',
    'src/Widgets/Popover.vala',
    config_header,
    c_args: [
      '-DGWEATHER_I_KNOW_THIS_IS_UNSTABLE',
    ],
    dependencies: indicator_deps,
    install: true,
    install_dir: wingpanel_dep.get_pkgconfig_variable ('indicatorsdir'),
  )
endif

meson.add_install_script ('meson_post_install.py')
