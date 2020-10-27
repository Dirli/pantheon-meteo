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
    public struct SunState {
        GLib.DateTime day;
        GLib.DateTime sunrise;
        GLib.DateTime sunset;
    }

    public class MainWindow : Gtk.Window {
        private Gtk.Grid view;
        private Meteo.Widgets.Header header;
        private GLib.Settings settings;
        private Meteo.Widgets.Statusbar statusbar;
        private string cur_idplace;
        private bool _personal_key;

        private bool personal_key {
            get { return _personal_key; }
            set {
                if (_personal_key != value) {
                    _personal_key = value;
                    statusbar.mod_provider_label (personal_key);
                }
            }
        }

        public MainWindow (MeteoApp app) {
            set_application (app);
            set_default_size (950, 750);
            set_size_request (950, 750);
            window_position = Gtk.WindowPosition.CENTER;
            resizable = false;

            settings = Meteo.Services.SettingsManager.get_default ();
            cur_idplace = "";

            Gtk.CssProvider provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/elementary/meteo/application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            header = new Meteo.Widgets.Header (this);
            header.upd_button.clicked.connect (() => {
                change_view ();
            });
            set_titlebar (header);

            view = new Gtk.Grid ();
            view.expand = true;
            view.halign = view.valign = Gtk.Align.FILL;

            insert_def_page ();

            statusbar = Meteo.Widgets.Statusbar.get_default ();
            view.attach (statusbar, 0, 1, 1, 1);

            personal_key = settings.get_string ("personal-key").replace ("/", "") == "";

            add (view);
            determine_loc ();
        }

        private void insert_def_page () {
            var default_page = new Meteo.Widgets.Default ();
            default_page.expand = true;
            var exist_widget = view.get_child_at (0,0);
            if (exist_widget != null) {
                exist_widget.destroy ();
            }
            default_page.show_all ();
            view.attach (default_page, 0, 0, 1, 1);
        }

        public void start_follow () {
            settings.changed["idplace"].connect (on_idplace_change);
        }

        private void determine_loc () {
            string idp = settings.get_string ("idplace");
            if (settings.get_boolean ("auto")) {
                Meteo.Services.Location.geolocate ();
            } else if (idp == "" || idp == "0") {
                header.set_custom_title (new Meteo.Services.Location ());
                header.show_all ();
            } else {
                change_view ();
            }
        }

        public void change_view (string statusbar_msg = "") {
            header.custom_title = null;

            string location_title = settings.get_string ("location") + ", ";
            location_title += settings.get_string ("country");
            header.set_title (location_title);

            var widget = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);

            string idplace = settings.get_string ("idplace");
            string lang = Gtk.get_default_language ().to_string ().substring (0, 2);
            string units = settings.get_string ("units");

            string api_key = settings.get_string ("personal-key").replace ("/", "");
            if (api_key == "") {
                api_key = Constants.API_KEY;
                personal_key = false;
            } else {
                personal_key = true;
            }

            string uri_query = "?id=" + idplace + "&APPID=" + api_key + "&units=" + units + "&lang=" + lang;

            string uri = Constants.OWM_API_ADDR + "weather" + uri_query;
            Json.Object? today_obj = Meteo.Services.Connector.get_owm_data (uri, "current");
            string upd_msg;

            SunState sun_state = {};
            var sys = today_obj.get_object_member ("sys");
            sun_state.sunrise = new GLib.DateTime.from_unix_local (sys.get_int_member ("sunrise"));
            sun_state.sunset = new GLib.DateTime.from_unix_local (sys.get_int_member ("sunset"));
            sun_state.day = new GLib.DateTime.from_unix_local ((int64) today_obj.get_int_member ("dt"));

            if (statusbar_msg == "") {
                GLib.DateTime upd_dt = sun_state.day;
                upd_msg = _("Last update:") + " " + upd_dt.format ("%a, %e  %b %R");
            } else {
                upd_msg = statusbar_msg;
            }
            statusbar.add_msg (upd_msg);

            Gtk.Grid today = new Meteo.Widgets.Today (today_obj, units, sun_state);

            uri = Constants.OWM_API_ADDR + "forecast" + uri_query;
            Json.Object? forecast_obj = Meteo.Services.Connector.get_owm_data (uri, "forecast");
            Gtk.Grid forecast = new Meteo.Widgets.Forecast (forecast_obj, units, sun_state);

            Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            widget.pack_start (today, true, false, 0);
            widget.pack_start (separator, false, true, 0);
            widget.pack_start (forecast, true, true, 0);

            this.view.get_child_at (0,0).destroy ();
            widget.expand = true;
            widget.show_all ();
            this.view.attach (widget, 0, 0, 1, 1);
        }

        private void on_idplace_change () {
            header.refresh_btns ();
            string actual_idplace = settings.get_string ("idplace");
            //FIXME: After recording a new location or updating an old one,
            // the event fires an arbitrary number of times (1-3). Changed
            // event is generated on all properties. I don't know why
            // warning (@"Changed setting idplace: $actual_idplace");
            if (cur_idplace != actual_idplace) {
                cur_idplace = actual_idplace;
                if (actual_idplace == "" || actual_idplace == "0") {
                    insert_def_page ();
                    determine_loc ();
                } else {
                    change_view ();
                }
            }
        }
    }
}
