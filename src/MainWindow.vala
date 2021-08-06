/*
* Copyright (c) 2018-2021 Dirli <litandrej85@gmail.com>
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
    public class MainWindow : Gtk.Window {
        public GLib.Settings settings;

        private Gtk.Stack main_stack;
        private Views.WeatherPage weather_page;

        private Widgets.Header header;
        private Widgets.Statusbar statusbar;

        private Services.Geolocation geo_service;
        private Services.Connector con_service;

        public string api_key {
            owned get {
                string _api_key = settings.get_string ("personal-key").replace ("/", "");
                if (_api_key == "") {
                    return Constants.API_KEY;
                }

                return _api_key;
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
            set_default_size (750, 400);

            settings = new GLib.Settings (Constants.APP_NAME);
            settings.changed["idplace"].connect (fetch_data);
            settings.changed["auto"].connect (determine_loc);

            con_service = new Services.Connector ();
            geo_service = new Services.Geolocation (api_key);
            geo_service.existing_location.connect (() => {
                fetch_data ();
            });
            geo_service.new_location.connect ((loc) => {
                Utils.clear_cache ();
                settings.set_string ("location", loc.location);
                settings.set_string ("country", loc.country);
                settings.set_string ("idplace", loc.idplace);
            });

            build_ui ();

            geo_service.show_message.connect (statusbar.add_msg);
            // con_service.show_message.connect (statusbar.add_msg);

            settings.bind ("auto", header, "auto-location", GLib.SettingsBindFlags.GET);
            settings.bind ("idplace", header, "idplace", GLib.SettingsBindFlags.GET);
            settings.bind ("longitude", geo_service, "longitude", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("latitude", geo_service, "latitude", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("symbolic", con_service, "use-symbolic", GLib.SettingsBindFlags.GET);
            // settings.bind ("forecast-update", con_service, "period-update", GLib.SettingsBindFlags.DEFAULT);

            if (settings.get_boolean ("auto")) {
                if (settings.get_string ("idplace") == "") {
                    reset_location ();
                }

                if (!geo_service.auto_detect ()) {
                    settings.set_boolean ("auto", false);
                }
            } else {
                fetch_data ();
            }
        }

        private void build_ui () {
            header = new Widgets.Header ();
            header.update_data.connect (() => {
                fetch_data ();
            });
            header.show_preferences.connect (() => {
                var preferences = new Dialogs.Preferences (this);
                preferences.run ();
            });
            header.change_location.connect (determine_loc);

            set_titlebar (header);

            main_stack = new Gtk.Stack ();
            main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            main_stack.expand = true;

            var default_page = new Views.DefaultPage ();
            default_page.activated.connect ((index) => {
                remove_custome_title ();
                settings.set_boolean ("auto", index == 0 ? true : false);
            });
            weather_page = new Views.WeatherPage ();

            main_stack.add_named (default_page, "default");
            main_stack.add_named (weather_page, "weather");

            statusbar = new Widgets.Statusbar ();
            statusbar.mod_provider_label (settings.get_string ("personal-key").replace ("/", "") != "");

            var view_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            view_box.add (main_stack);
            view_box.add (statusbar);
            view_box.show_all ();

            add (view_box);
        }

        public void remove_custome_title () {
            if (header.get_custom_title () != null) {
                header.custom_title = null;
            }
        }

        private void reset_location () {
            settings.reset ("longitude");
            settings.reset ("latitude");
            settings.reset ("location");
            settings.reset ("country");

            weather_page.reset_today ();
        }

        private void determine_loc () {
            reset_location ();

            settings.set_string ("idplace", "");

            if (settings.get_boolean ("auto")) {
                if (geo_service.auto_detect ()) {
                    return;
                }
            }

            geo_service.manually_detect ();
            header.set_custom_title (geo_service.location_entry);
            header.show_all ();
        }

        public void fetch_data () {
            string idplace = settings.get_string ("idplace");
            if (idplace == "") {
                header.set_title ("Meteo");
                main_stack.set_visible_child_name ("default");
                return;
            }

            var weather_provider = con_service.get_weather_provider (api_key, settings.get_string ("idplace"));

            remove_custome_title ();
            header.set_title (settings.get_string ("location") + ", " + settings.get_string ("country"));

            var units = settings.get_string ("units");

            var today_weather = weather_provider.get_today_forecast (units);
            if (today_weather != null) {
                GLib.DateTime upd_dt = new GLib.DateTime.from_unix_local (today_weather.date);
                statusbar.add_msg (_("Last update: ") + upd_dt.format ("%a, %e  %b %R"));

                weather_page.set_sun_state (weather_provider.sunrise, weather_provider.sunset);
                weather_page.update_today (today_weather);
            }

            var forecast_array = weather_provider.get_long_forecast (units);
            if (forecast_array.size > 0) {
                fill_forecast (forecast_array);
            }

            main_stack.set_visible_child_name ("weather");
        }

        private void fill_forecast (Gee.ArrayList<Structs.WeatherStruct?> struct_list) {
            weather_page.clear_forecast ();

            int periods = Utils.get_forecast_periods (struct_list.@get (0).date);
            int days_count = (int) GLib.Math.round (struct_list.size / 8.0);
            days_count = days_count < 5 ? days_count : periods == 0 ? 5 : 6;

            int elem_index;
            GLib.DateTime date;

            for (int day_index = 0; day_index < days_count; day_index++) {
                for (int time_index = 0; time_index < 8; time_index++) {
                    elem_index = Utils.get_time_index (periods, day_index, time_index);

                    var weather_struct = struct_list.@get (elem_index);
                    date = new GLib.DateTime.from_unix_local (weather_struct.date);

                    if (time_index == 0) {
                        weather_page.add_day_label (date, day_index);
                    }

                    if (!weather_page.add_forecast_time (day_index, date, weather_struct.icon_name, weather_struct.temp)) {
                        break;
                    }

                    if (day_index == 0 && periods != 0 && periods == (time_index + 1) ) {break;}
                    if ((day_index + 1) == days_count && periods != 0 && (8 - periods) == time_index + 1 ) {break;}
                }
            }

            weather_page.show_all ();
        }
    }
}
