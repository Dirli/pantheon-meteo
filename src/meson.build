executable(
    meson.project_name(),
    'Constants.vala',
    'MainWindow.vala',
    'Meteo.vala',
    'Services/Connector.vala',
    'Services/GeoLocate.vala',
    'Services/Settings.vala',
    'Utils/Iconame.vala',
    'Utils/Utils.vala',
    'Widgets/Current.vala',
    'Widgets/Forecast.vala',
    'Widgets/Header.vala',
    'Widgets/Preferences.vala',
    'Widgets/Ticket.vala',
    'Widgets/Today.vala',
    asresources,
    vala_args: vala_args,
    dependencies: [
        gio_dep,
        gobject_dep,
        glib_dep,
        gtk_dep,
        libsoup_dep,
        json_dep,
        geocode_dep,
        granite_dep
    ],
    link_args: ['-lm'],
    install : true
)


if get_option('indicator')
    shared_library(
        'meteo',
        'Indicator.vala',
        'Constants.vala',
        'Widgets/Panel.vala',
        'Widgets/Popover.vala',
        'Utils/Iconame.vala',
        'Utils/Utils.vala',
        'Services/Connector.vala',
        'Services/ILogindManager.vala',
        'Services/Settings.vala',
        dependencies: [
            gio_dep,
            gobject_dep,
            glib_dep,
            gio_unix_dep,
            gtk_dep,
            libsoup_dep,
            json_dep,
            wingpanel_dep
        ],
        link_args: ['-lm'],
        install: true,
        install_dir: wingpanel_dep.get_pkgconfig_variable('indicatorsdir'),
    )
endif
