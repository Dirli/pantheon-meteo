/*
* Copyright (c) 2018 Dirli <litandrej85@gmail.com>
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*/

namespace Meteo {
    public class Widgets.Popover : Gtk.Grid {
        public signal void hide_indicator ();

        private Gtk.Label city_item;
        private Gtk.Label humidity_item;
        private Gtk.Label pressure_item;
        private Gtk.Label wind_item;
        private Gtk.Label cloud_item;
        private Gtk.Label sunrise_item;
        private Gtk.Label sunset_item;

        public Popover () {
            Object (orientation: Gtk.Orientation.HORIZONTAL,
                    hexpand: true,
                    row_spacing: 10);

        }

        construct {
            city_item = new Gtk.Label ("-");
            city_item.get_style_context ().add_class ("city");
            city_item.margin_top = 10;

            humidity_item = new Gtk.Label ("-");
            humidity_item.halign = Gtk.Align.START;
            Gtk.Box humidity_box = create_box (humidity_item, create_icon ("weather-showers", _("Humidity")));

            pressure_item = new Gtk.Label ("-");
            pressure_item.halign = Gtk.Align.START;
            Gtk.Box pressure_box = create_box (pressure_item, create_icon ("weather-severe-alert", _("Pressure")));

            wind_item = new Gtk.Label ("-");
            wind_item.halign = Gtk.Align.START;
            Gtk.Box wind_box = create_box (wind_item, create_icon ("weather-windy", _("Wind")));

            cloud_item = new Gtk.Label ("-");
            cloud_item.halign = Gtk.Align.START;
            Gtk.Box cloud_box = create_box (cloud_item, create_icon ("weather-overcast", _("Clouds")));

            sunrise_item = new Gtk.Label ("-");
            sunrise_item.halign = Gtk.Align.START;
            Gtk.Box sunrise_box = create_box (sunrise_item, create_icon ("daytime-sunrise", _("Sunrise")));

            sunset_item = new Gtk.Label ("-");
            sunset_item.halign = Gtk.Align.START;
            Gtk.Box sunset_box = create_box (sunset_item, create_icon ("daytime-sunset", _("Sunset")));

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.hexpand = true;

            var hide_button = new Gtk.ModelButton ();
            hide_button.text = _("Hide indicator");

            hide_button.clicked.connect (() => {
                hide_indicator ();
            });

            var app_button = new Gtk.ModelButton ();
            app_button.text = _("Start meteo");

            app_button.clicked.connect (() => {
                var app_info = new GLib.DesktopAppInfo (Constants.APP_NAME + ".desktop");

                if (app_info == null) {
                    return;
                }

                try {
                    app_info.launch (null, null);
                } catch (Error e) {
                    warning ("Unable to launch io.elementary.meteo.desktop: %s", e.message);
                }
            });

            attach (city_item,    0, 0, 1, 1);
            attach (humidity_box, 0, 1, 1, 1);
            attach (pressure_box, 0, 2, 1, 1);
            attach (wind_box,     0, 3, 1, 1);
            attach (cloud_box,    0, 4, 1, 1);
            attach (sunrise_box,  0, 5, 1, 1);
            attach (sunset_box,   0, 6, 1, 1);
            attach (separator,    0, 7, 1, 1);
            attach (hide_button,  0, 8, 1, 1);
            attach (app_button,   0, 9, 1, 1);
        }

        public void update_state (string city_name,
                                  string humidity_str,
                                  string pressure_str,
                                  string wind_str,
                                  string cloud_str,
                                  string sunrise_str,
                                  string sunset_str) {
            city_item.label = city_name;
            humidity_item.label = humidity_str;
            pressure_item.label = pressure_str;
            wind_item.label = wind_str;
            cloud_item.label = cloud_str;
            sunrise_item.label = sunrise_str;
            sunset_item.label = sunset_str;
        }

        private Gtk.Image create_icon (string icon_name, string tooltip) {
            Gtk.Image icon = new Gtk.Image ();
            icon.set_from_icon_name (icon_name + "-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            icon.margin_start = icon.margin_end = 5;
            icon.tooltip_text = tooltip;

            return icon;
        }

        private Gtk.Box create_box (Gtk.Label elem_label, Gtk.Image elem_img) {
            Gtk.Box elem_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            elem_box.pack_start (elem_img, false, false, 0);
            elem_box.pack_start (elem_label, false, false, 0);
            elem_box.margin_start = 20;

            return elem_box;
        }
    }
}
