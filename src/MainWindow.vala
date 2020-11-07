/*
* Copyright (c) 2018-2020 Dirli <litandrej85@gmail.com>
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
    public struct WeatherStruct {
        public string description;
        public string icon_name;
        public string temp;
        public string pressure;
        public string wind;
        public string clouds;
        public string humidity;
    }

    public struct LocationStruct {
        public string location;
        public string country;
        public string idplace;
    }

    public class MainWindow : Gtk.Window {
        public GLib.Settings settings;

        private Gtk.Stack main_stack;
        private Views.WeatherPage weather_page;

        private Widgets.Header header;
        private Widgets.Statusbar statusbar;

        private Services.Geolocation geo_service;

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

            settings = Services.SettingsManager.get_default ();
            settings.changed["idplace"].connect (fetch_data);
            settings.changed["auto"].connect (determine_loc);

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

            settings.bind ("auto", header, "auto-location", GLib.SettingsBindFlags.GET);
            settings.bind ("idplace", header, "idplace", GLib.SettingsBindFlags.GET);
            settings.bind ("longitude", geo_service, "longitude", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("latitude", geo_service, "latitude", GLib.SettingsBindFlags.DEFAULT);

            if (settings.get_boolean ("auto")) {
                if (settings.get_string ("idplace") == "") {
                    reset_location ();
                }

                geo_service.auto_detect ();
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

            statusbar = Widgets.Statusbar.get_default ();

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
                geo_service.auto_detect ();
            } else {
                geo_service.manually_detect ();
                header.set_custom_title (geo_service.location_entry);
                header.show_all ();
            }
        }

        public void fetch_data () {
            string idplace = settings.get_string ("idplace");
            if (idplace == "") {
                header.set_title ("Meteo");
                main_stack.set_visible_child_name ("default");
                return;
            }

            remove_custome_title ();
            header.set_title (settings.get_string ("location") + ", " + settings.get_string ("country"));

            string lang = Gtk.get_default_language ().to_string ().substring (0, 2);
            var units = settings.get_string ("units");

            string uri_query = "?id=" + idplace + "&APPID=" + api_key + "&units=" + units + "&lang=" + lang;

            Json.Object? today_obj = Services.Connector.get_owm_data ("weather" + uri_query, "current");

            GLib.DateTime upd_dt = new GLib.DateTime.from_unix_local (today_obj.get_int_member ("dt"));
            var upd_msg = _("Last update: ") + upd_dt.format ("%a, %e  %b %R");

            statusbar.add_msg (upd_msg);

            if (today_obj != null) {
                var sys = today_obj.get_object_member ("sys");
                weather_page.set_sun_state (sys.get_int_member ("sunrise"), sys.get_int_member ("sunset"));
                fill_today (today_obj, units);
            }

            Json.Object? forecast_obj = Services.Connector.get_owm_data ("forecast" + uri_query, "forecast");
            if (forecast_obj != null) {
                Json.Array forecast_list = forecast_obj.get_array_member ("list");

                if (forecast_list.get_length () > 0) {
                    fill_forecast (forecast_list, units);
                }
            }

            main_stack.set_visible_child_name ("weather");
        }

        private void fill_today (Json.Object today_obj, string units) {
            var main_data = today_obj.get_object_member ("main");
            var weather = today_obj.get_array_member ("weather");

            WeatherStruct today_weather = {};

            today_weather.description = weather.get_object_element (0).get_string_member ("description");

            var icon_name = Utils.get_icon_name (weather.get_object_element (0).get_string_member ("icon"));
            if (settings.get_boolean ("symbolic")) {
                icon_name += "-symbolic";
            }
            today_weather.icon_name = icon_name;

            today_weather.temp = Utils.temp_format (units, main_data.get_double_member ("temp"));
            today_weather.pressure = Utils.pressure_format ((int) main_data.get_int_member ("pressure"));
            today_weather.humidity = "%d %%".printf ((int) main_data.get_int_member ("humidity"));

            Json.Object wind = today_obj.get_object_member ("wind");
            double? wind_speed = null;
            if (wind.has_member ("speed")) {
                wind_speed = wind.get_double_member ("speed");
            }

            double? wind_deg = null;
            if (wind.has_member ("deg")) {
                wind_deg = wind.get_double_member ("deg");
            }

            today_weather.wind = Utils.wind_format (units, wind_speed, wind_deg);

            var clouds = today_obj.get_object_member ("clouds");
            today_weather.clouds = "%d %%".printf ((int) clouds.get_int_member ("all"));

            weather_page.update_today (today_weather);
        }

        private void fill_forecast (Json.Array forecast_list, string units) {
            weather_page.clear_forecast ();

            int periods = Utils.get_forecast_periods (forecast_list.get_object_element (0).get_int_member ("dt"));

            int days_count = (int) GLib.Math.round (forecast_list.get_length () / 8.0);
            days_count = days_count < 5 ? days_count : periods == 0 ? 5 : 6;

            int elem_index;
            GLib.DateTime date;

            for (int day_index = 0; day_index < days_count; day_index++) {
                for (int time_index = 0; time_index < 8; time_index++) {
                    elem_index = Utils.get_time_index (periods, day_index, time_index);

                    var list_element = forecast_list.get_object_element (elem_index);
                    date = new GLib.DateTime.from_unix_local (list_element.get_int_member ("dt"));

                    if (time_index == 0) {
                        weather_page.add_day_label (date, day_index);
                    }

                    var icon_name = Utils.get_icon_name (list_element.get_array_member ("weather").get_object_element (0).get_string_member ("icon"));
                    if (settings.get_boolean ("symbolic")) {
                        icon_name += "-symbolic";
                    }

                    string temp = Utils.temp_format (units, list_element.get_object_member ("main").get_double_member ("temp"));
                    if (!weather_page.add_forecast_time (day_index, date, icon_name, temp)) {
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
