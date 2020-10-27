project (
    'io.elementary.meteo',
    ['vala', 'c'],
    version: '0.9.0'
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

common_deps = [
    dependency ('gio-2.0'),
    dependency ('gobject-2.0'),
    dependency ('glib-2.0'),
    dependency ('gtk+-3.0'),
    dependency ('libsoup-2.4'),
    dependency ('json-glib-1.0'),
    meson.get_compiler ('c').find_library ('m'),
]

app_deps = common_deps + [
    dependency ('geocode-glib-1.0'),
    dependency ('gweather-3.0'),
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
    'src/MainWindow.vala',
    'src/Meteo.vala',
    'src/Services/Connector.vala',
    'src/Services/Location.vala',
    'src/Services/Settings.vala',
    'src/Utils/Iconame.vala',
    'src/Utils/Utils.vala',
    'src/Widgets/About.vala',
    'src/Widgets/Default.vala',
    'src/Widgets/Forecast.vala',
    'src/Widgets/Header.vala',
    'src/Widgets/Preferences.vala',
    'src/Widgets/Statusbar.vala',
    'src/Widgets/Today.vala',
    asresources,
    vala_args: vala_args,
    c_args: [
        '-DGWEATHER_I_KNOW_THIS_IS_UNSTABLE',
    ],
    dependencies: app_deps,
    install : true
)

if get_option ('indicator')
    # indicator_deps = common_deps
    wingpanel_dep = dependency ('wingpanel-2.0')

    indicator_deps = common_deps + [
        dependency ('gio-unix-2.0'),
        wingpanel_dep
    ]

    shared_library (
        'meteo',
        'src/Indicator.vala',
        'src/Constants.vala',
        'src/Widgets/Panel.vala',
        'src/Widgets/Popover.vala',
        'src/Utils/Iconame.vala',
        'src/Utils/Utils.vala',
        'src/Services/Connector.vala',
        'src/Services/ILogindManager.vala',
        'src/Services/Settings.vala',
        dependencies: indicator_deps,
        install: true,
        install_dir: wingpanel_dep.get_pkgconfig_variable ('indicatorsdir'),
    )
endif

meson.add_install_script ('meson/post_install.py')
