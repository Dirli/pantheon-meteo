shared_library (
    'meteo',
    'Indicator.vala',
    'Panel.vala',
    'Popover.vala',
    indicator_files,
    config_header,
    c_args: [
      '-DGWEATHER_I_KNOW_THIS_IS_UNSTABLE',
    ],
    dependencies: indicator_deps,
    install: true,
    install_dir: wingpanel_dep.get_pkgconfig_variable ('indicatorsdir'),
  )