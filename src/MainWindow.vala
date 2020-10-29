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
        public GLib.Settings settings;

        private Gtk.Stack main_stack;
        private Gtk.Box weather_page;

        private Meteo.Widgets.Header header;
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
            Object (application: app,
                    window_position: Gtk.WindowPosition.CENTER);

            Gtk.CssProvider provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/elementary/meteo/application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        construct {
            set_default_size (950, 750);

            settings = Meteo.Services.SettingsManager.get_default ();
            cur_idplace = "";

            build_ui ();

            personal_key = settings.get_string ("personal-key").replace ("/", "") == "";

            determine_loc ();
        }

        private void build_ui () {
            header = new Meteo.Widgets.Header (this);
            header.upd_button.clicked.connect (() => {
                change_view ();
            });
            header.show_preferences.connect (() => {
                var preferences = new Meteo.Dialogs.Preferences (this);
                preferences.run ();
            });

            set_titlebar (header);

            main_stack = new Gtk.Stack ();
            main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            main_stack.expand = true;

            var default_page = new Meteo.Widgets.Default ();
            weather_page = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);

            main_stack.add_named (default_page, "default");
            main_stack.add_named (weather_page, "weather");

            statusbar = Meteo.Widgets.Statusbar.get_default ();

            var view_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            view_box.add (main_stack);
            view_box.add (statusbar);
            view_box.show_all ();

            add (view_box);
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

            foreach (unowned Gtk.Widget item in weather_page.get_children ()) {
                weather_page.remove (item);
            }

            string location_title = settings.get_string ("location") + ", ";
            location_title += settings.get_string ("country");
            header.set_title (location_title);

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
            Json.Object? today_obj = Services.Connector.get_owm_data (uri, "current");
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

            Gtk.Grid today = new Widgets.Today (today_obj, units, sun_state);

            uri = Constants.OWM_API_ADDR + "forecast" + uri_query;
            Json.Object? forecast_obj = Services.Connector.get_owm_data (uri, "forecast");
            Gtk.Grid forecast = new Widgets.Forecast (forecast_obj, units, sun_state);

            weather_page.add (today);
            weather_page.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            weather_page.add (forecast);

            weather_page.show_all ();
            main_stack.set_visible_child_name ("weather");
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
                    main_stack.set_visible_child_name ("default");
                    determine_loc ();
                } else {
                    change_view ();
                }
            }
        }
    }
}
