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
            settings.changed["auto"].connect (determine_loc);

            con_service = new Services.Connector ();
            geo_service = new Services.Geolocation (api_key);
            geo_service.changed_location.connect (on_changed_location);

            build_ui ();

            geo_service.show_message.connect (statusbar.add_msg);
            // con_service.show_message.connect (statusbar.add_msg);

            settings.bind ("auto", header, "auto-location", GLib.SettingsBindFlags.GET);
            settings.bind ("idplace", header, "idplace", GLib.SettingsBindFlags.GET);
            settings.bind ("symbolic", con_service, "use-symbolic", GLib.SettingsBindFlags.GET);

            if (settings.get_boolean ("auto")) {
                geo_service.auto_detect ();
            } else {
                init_location ();
                fetch_data ();
            }
        }

        private void build_ui () {
            header = new Widgets.Header ();
            header.update_data.connect (fetch_data);
            header.changed_location.connect (on_changed_location);
            header.change_location.connect (determine_loc);
            header.show_preferences.connect (() => {
                var preferences = new Dialogs.Preferences (this);
                preferences.run ();
            });

            set_titlebar (header);

            main_stack = new Gtk.Stack ();
            main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            main_stack.expand = true;

            var default_page = new Views.DefaultPage ();
            default_page.activated.connect ((index) => {
                header.remove_custome_title ();
                settings.set_boolean ("auto", index == 0 ? true : false);
            });
            weather_page = new Views.WeatherPage ();

            main_stack.add_named (default_page, "default");
            main_stack.add_named (weather_page, "weather");
            main_stack.set_visible_child_name ("default");

            statusbar = new Widgets.Statusbar ();
            statusbar.mod_provider_label (settings.get_string ("personal-key").replace ("/", "") != "");

            var view_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            view_box.add (main_stack);
            view_box.add (statusbar);
            view_box.show_all ();

            add (view_box);
        }

        private void on_changed_location (Structs.LocationStruct loc) {
            reset_location ();
            Utils.clear_cache ();

            settings.set_string ("city", loc.city);
            settings.set_string ("country", loc.country);
            settings.set_double ("latitude", loc.latitude);
            settings.set_double ("longitude", loc.longitude);

            if (settings.get_enum ("provider") == Enums.Provider.OWM) {
                var idplace = geo_service.determine_id (loc.longitude, loc.latitude, api_key);
                settings.set_string ("idplace", idplace.to_string ());
            }

            init_location ();
            fetch_data ();
        }

        private void reset_location () {
            main_stack.set_visible_child_name ("default");

            settings.reset ("longitude");
            settings.reset ("latitude");
            settings.reset ("city");
            settings.reset ("country");

            settings.set_string ("idplace", "");

            weather_page.reset_today ();
        }

        private void determine_loc () {
            if (settings.get_boolean ("auto")) {
                geo_service.auto_detect ();
            } else {
                header.manual_detect ();
            }
        }

        private void init_location () {
            var city = settings.get_string ("city");
            var country = settings.get_string ("country");

            header.remove_custome_title ();
            if (city == "" || country == "") {
                header.set_title ("Meteo");
            } else {
                header.set_title (@"$(settings.get_string ("city")), $(settings.get_string ("country"))");
            }
        }

        private Structs.LocationStruct get_location () {
            Structs.LocationStruct location = {};

            location.city = settings.get_string ("city");
            location.country = settings.get_string ("country");
            location.latitude = settings.get_double ("latitude");
            location.longitude = settings.get_double ("longitude");
            location.idplace = settings.get_string ("idplace");

            return location;
        }

        public void fetch_data () {
            var weather_provider = con_service.get_weather_provider ((Enums.Provider) settings.get_enum ("provider"),
                                                                     get_location (),
                                                                     api_key);

            if (weather_provider == null) {
                return;
            }

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
