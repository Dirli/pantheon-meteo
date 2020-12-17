data_dir = join_paths (get_option ('prefix'), get_option ('datadir'))

install_data (
    meson.project_name () + '.gschema.xml',
    install_dir: join_paths (get_option ('datadir'), 'glib-2.0/schemas')
)

icon_dir = join_paths (data_dir, 'icons', 'hicolor')

foreach i : ['16', '24', '32', '48', '64']
    install_data (
        join_paths ('icons', i, meson.project_name () + '.svg'),
        install_dir: join_paths (icon_dir, i + 'x' + i, 'apps')
    )
endforeach

install_data (
    meson.project_name () + '.desktop',
    install_dir: join_paths (data_dir, 'applications')
)
