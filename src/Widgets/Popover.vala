/*
 * Copyright (c) 2018-2021 Dirli <litandrej85@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
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

        public string city_name {
            set {
                city_item.label = value;
            }
        }

        public Popover () {
            Object (orientation: Gtk.Orientation.HORIZONTAL,
                    hexpand: true,
                    row_spacing: 10);
        }

        construct {
            city_item = new Gtk.Label ("-");
            city_item.get_style_context ().add_class ("city");
            city_item.margin_top = 10;

            humidity_item = new Gtk.Label (null);
            pressure_item = new Gtk.Label (null);
            wind_item = new Gtk.Label (null);
            cloud_item = new Gtk.Label (null);
            sunrise_item = new Gtk.Label (null);
            sunset_item = new Gtk.Label (null);

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

            attach (city_item, 0, 0);
            attach (create_box (humidity_item, create_icon ("weather-showers", _("Humidity"))), 0, 1);
            attach (create_box (pressure_item, create_icon ("weather-severe-alert", _("Pressure"))), 0, 2);
            attach (create_box (wind_item, create_icon ("weather-windy", _("Wind"))), 0, 3);
            attach (create_box (cloud_item, create_icon ("weather-overcast", _("Clouds"))), 0, 4);
            attach (create_box (sunrise_item, create_icon ("daytime-sunrise", _("Sunrise"))), 0, 5);
            attach (create_box (sunset_item, create_icon ("daytime-sunset", _("Sunset"))), 0, 6);
            attach (separator, 0, 7);
            attach (hide_button, 0, 8);
            attach (app_button, 0, 9);
        }

        public void update_state (Structs.WeatherStruct w, int64 sunrise, int64 sunset) {
            humidity_item.label = w.humidity;
            pressure_item.label = w.pressure;
            wind_item.label = w.wind;
            cloud_item.label = w.clouds;

            if (sunrise > 0) {
                sunrise_item.label = Utils.time_format (new DateTime.from_unix_local (sunrise));
            }

            if (sunset > 0) {
                sunset_item.label = Utils.time_format (new DateTime.from_unix_local (sunset));
            }
        }

        private Gtk.Image create_icon (string icon_name, string tooltip) {
            Gtk.Image icon = new Gtk.Image ();
            icon.set_from_icon_name (icon_name + "-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            icon.margin_start = icon.margin_end = 5;
            icon.tooltip_text = tooltip;

            return icon;
        }

        private Gtk.Box create_box (Gtk.Label elem_label, Gtk.Image elem_img) {
            elem_label.halign = Gtk.Align.START;

            Gtk.Box elem_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            elem_box.pack_start (elem_img, false, false, 0);
            elem_box.pack_start (elem_label, false, false, 0);
            elem_box.margin_start = 20;

            return elem_box;
        }
    }
}
