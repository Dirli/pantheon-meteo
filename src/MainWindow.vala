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
    public class MainWindow : Gtk.Window {
        public GLib.Settings settings;

        private Gtk.Stack main_stack;
        private Views.WeatherPage weather_page;
        private Views.WaitingPage waiting_page;
        private Granite.Widgets.AlertView alert_page;

        private Widgets.Header header;

        private Services.Geolocation geo_service;
        private Services.Connector con_service;
        private Providers.AbstractProvider? weather_provider;

        private Gtk.Label provider_label;

        private const ActionEntry[] ACTION_ENTRIES = {
            { Constants.ACTION_QUIT, action_quit },
            { Constants.ACTION_PREFERENCES, action_preferences },
        };

        public MainWindow (MeteoApp app) {
            Object (application: app,
                    window_position: Gtk.WindowPosition.CENTER);

            Gtk.CssProvider provider = new Gtk.CssProvider ();
            provider.load_from_resource ("/io/elementary/meteo/application.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_QUIT, {"<Control>q"});
            application.set_accels_for_action (Constants.ACTION_PREFIX + Constants.ACTION_PREFERENCES, {"<Control>p"});
        }

        construct {
            var actions = new GLib.SimpleActionGroup ();
            actions.add_action_entries (ACTION_ENTRIES, this);
            insert_action_group ("win", actions);

            set_default_size (750, 400);

            settings = new GLib.Settings (Constants.APP_NAME);

            con_service = new Services.Connector ();
            geo_service = new Services.Geolocation ();

            build_ui ();

            settings.bind ("auto", header, "auto-location", GLib.SettingsBindFlags.GET);
            settings.bind ("idplace", header, "idplace", GLib.SettingsBindFlags.GET);
            settings.bind ("days-count", weather_page, "max-days", GLib.SettingsBindFlags.GET);

            on_changed_provider ();
            geo_service.changed_location.connect (on_changed_location);

            settings.changed["auto"].connect (determine_loc);
            settings.changed["provider"].connect (on_changed_provider);
            settings.changed["symbolic"].connect (on_changed_symbolic);
            settings.changed["units"].connect (on_changed_units);

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
            header.show_preferences.connect (action_preferences);

            set_titlebar (header);

            var default_page = new Views.DefaultPage ();
            default_page.activated.connect ((index) => {
                header.remove_custome_title ();
                settings.set_boolean ("auto", index == 0 ? true : false);
            });
            alert_page = new Granite.Widgets.AlertView (_("Something went wrong"), "", "process-error");
            waiting_page = new Views.WaitingPage ();
            weather_page = new Views.WeatherPage ();

            main_stack = new Gtk.Stack ();
            main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
            main_stack.expand = true;

            main_stack.add_named (default_page, "default");
            main_stack.add_named (waiting_page, "waiting");
            main_stack.add_named (alert_page, "alert");
            main_stack.add_named (weather_page, "weather");

            main_stack.set_visible_child_name ("default");

            provider_label = new Gtk.Label (null);
            provider_label.margin_bottom = 12;

            var view_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            view_box.add (main_stack);
            view_box.add (provider_label);

            view_box.show_all ();

            main_stack.notify["visible-child-name"].connect (on_changed_child);
            add (view_box);
        }

        private void action_quit () {
            destroy ();
        }

        private void action_preferences () {
            var preferences = new Dialogs.Preferences (this);
            preferences.show_all ();
            preferences.run ();
        }

        private void on_changed_provider () {
            weather_provider = null;

            var provider_type = (Enums.ForecastProvider) settings.get_enum ("provider");
            weather_provider = con_service.get_weather_provider (provider_type,
                                                                 get_location (),
                                                                 settings.get_string ("personal-key").replace ("/", ""));

            if (weather_provider != null) {
                weather_provider.updated_today.connect (fill_today);
                weather_provider.updated_long.connect (fill_forecast);
                weather_provider.show_alert.connect (on_show_alert);

                provider_label.set_label (_("Provider: ") + provider_type.to_string ());

                on_changed_symbolic ();
                on_changed_units ();

                update_place_id ();
            }
        }

        private void on_changed_symbolic () {
            if (weather_provider != null) {
                weather_provider.use_symbolic = settings.get_boolean ("symbolic");
            }
        }

        private void on_changed_units () {
            if (weather_provider != null) {
                weather_provider.units = settings.get_int ("units");
            }
        }

        private void on_changed_child () {
            var view_name = main_stack.get_visible_child_name ();
            if (view_name != null) {
                waiting_page.start_spinner (view_name == "waiting" ? true : false);
            }
        }

        private void on_changed_location (Structs.LocationStruct loc) {
            reset_location ();

            settings.set_string ("city", loc.city);
            settings.set_string ("country", loc.country);
            settings.set_double ("latitude", loc.latitude);
            settings.set_double ("longitude", loc.longitude);

            if (weather_provider != null) {
                weather_provider.update_location (loc);
                update_place_id ();
            }
        }

        private void on_show_alert (uint alert_code) {
            alert_page.description = Utils.parse_code (alert_code);
            main_stack.set_visible_child_name ("alert");
        }

        private void update_place_id () {
            if (settings.get_string ("idplace") == "") {
                Utils.clear_cache ();
                waiting_page.update_page_label (_("Updating the location..."));

                weather_provider.get_place_id ((res) => {
                    settings.set_string ("idplace", res);
                    init_location ();
                    fetch_data ();
                });
            }
        }

        private void reset_location () {
            main_stack.set_visible_child_name ("default");

            settings.reset ("longitude");
            settings.reset ("latitude");
            settings.reset ("city");
            settings.reset ("country");
            settings.reset ("idplace");

            weather_page.reset_today ();
            weather_page.clear_forecast ();
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
            if (weather_provider == null) {
                return;
            }

            waiting_page.update_page_label (_("Loading the forecast..."));
            main_stack.set_visible_child_name ("waiting");
            weather_provider.update_forecast (true);
        }

        private void fill_today (Structs.WeatherStruct today_weather) {
            weather_page.set_sun_state (weather_provider.sunrise, weather_provider.sunset);
            weather_page.update_today (today_weather);

            main_stack.set_visible_child_name ("weather");
        }

        private void fill_forecast (Gee.ArrayList<Structs.WeatherStruct?> struct_list) {
            weather_page.clear_forecast ();

            struct_list.@foreach ((weather_iter) => {
                if (!weather_page.add_forecast_time (new GLib.DateTime.from_unix_local (weather_iter.date),
                                                weather_iter.icon_name,
                                                weather_iter.temp)) {
                    return false;
                }

                return true;
            });

            weather_page.show_all ();
        }
    }
}
