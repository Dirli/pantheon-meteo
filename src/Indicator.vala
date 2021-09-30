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

[DBus (name = "org.freedesktop.login1.Manager")]
interface ILogindManager : DBusProxy {
    public abstract signal void prepare_for_sleep (bool start);
}

namespace Meteo {
    private const string CITY_FS = """
        .city {
            font-size: 130%;
        }
    """;

    public class Indicator : Wingpanel.Indicator {
        private GLib.Settings settings;
        private uint timeout_id;

        private Widgets.Panel? panel_wid = null;
        private Widgets.Popover? popover_wid = null;
        private ILogindManager? logind_manager;

        private Services.Connector con_service;
        private GLib.NetworkMonitor network_monitor;

        private Providers.AbstractProvider? weather_provider = null;

        public Indicator () {
            Object (code_name: "meteo-indicator");

            settings = new GLib.Settings (Constants.APP_NAME);
            visible = settings.get_boolean ("indicator");

            network_monitor = GLib.NetworkMonitor.get_default ();
            con_service = new Services.Connector ();

            init_weather_provider ();

            try {
                var provider = new Gtk.CssProvider ();
                provider.load_from_data (CITY_FS);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                logind_manager = GLib.Bus.get_proxy_sync (GLib.BusType.SYSTEM, Constants.LOGIND_BUS_NAME, Constants.LOGIND_BUS_PATH);
                if (logind_manager != null) {
                    logind_manager.prepare_for_sleep.connect ((start) => {
                        if (!start) {
                            start_watcher ();
                        }
                    });
                }
            } catch (Error e) {
                warning (e.message);
            }

            settings.changed["indicator"].connect (on_indicator_change);
            settings.changed["interval"].connect (on_interval_change);
            settings.changed["units"].connect (on_units_changed);
            settings.changed["idplace"].connect (on_idplace_changed);
        }

        public override Gtk.Widget get_display_widget () {
            if (panel_wid == null) {
                panel_wid = new Widgets.Panel ();
                if (visible) {
                    start_watcher ();

                    network_monitor.network_changed.connect (on_network_changed);
                }
            }

            return panel_wid;
        }

        public override Gtk.Widget? get_widget () {
            if (popover_wid == null) {
                popover_wid = new Widgets.Popover ();
                popover_wid.hide_indicator.connect (() => {
                    settings.set_boolean ("indicator", false);
                });
            }

            return popover_wid;
        }

        private bool fetch_data () {
            if (weather_provider == null || network_monitor.get_connectivity () != NetworkConnectivity.FULL) {
                timeout_id = 0;
                return false;
            }

            weather_provider.update_forecast (false);

            return true;
        }

        protected void on_indicator_change () {
            if (settings.get_boolean ("indicator")) {
                visible = true;
                network_monitor.network_changed.connect (on_network_changed);
            } else {
                visible = false;
                network_monitor.network_changed.disconnect (on_network_changed);
            }

            start_watcher ();
        }

        protected void on_interval_change () {
            start_watcher ();
        }

        private void on_network_changed (bool availabe) {
            if (network_monitor.get_connectivity () == NetworkConnectivity.FULL && timeout_id == 0) {
                start_watcher ();
            }
        }

        private void on_idplace_changed () {
            if (settings.get_string ("idplace") != "") {
                start_watcher ();
            }
        }

        private void on_units_changed () {
            if (weather_provider != null) {
                weather_provider.units = settings.get_int ("units");
                start_watcher ();
            }
        }

        private bool init_weather_provider () {
            Structs.LocationStruct location = {};

            location.city = settings.get_string ("city");
            location.country = settings.get_string ("country");
            location.latitude = settings.get_double ("latitude");
            location.longitude = settings.get_double ("longitude");
            location.idplace = settings.get_string ("idplace");

            weather_provider = con_service.get_weather_provider ((Enums.ForecastProvider) settings.get_enum ("provider"),
                                                                 location,
                                                                 settings.get_string ("personal-key").replace ("/", ""));
            if (weather_provider != null) {
                weather_provider.units = settings.get_int ("units");
                weather_provider.updated_today.connect (update_today);

                return true;
            }

            return false;
        }

        private void update_today (Structs.WeatherStruct weather_struct) {
            if (panel_wid != null) {
                panel_wid.update_state (weather_struct.temp, weather_struct.icon_name);

                if (popover_wid != null) {
                    popover_wid.update_state (settings.get_string ("city"),
                                              weather_struct,
                                              weather_provider.sunrise,
                                              weather_provider.sunset);
                }
            }
        }

        private void start_watcher () {
            stop_watcher ();

            if (!visible ||
                network_monitor.get_connectivity () != NetworkConnectivity.FULL ||
                !(weather_provider != null || init_weather_provider ())) {
                return;
            }

            var interval = settings.get_int ("interval") * 3600;
            interval = interval >= 3600 ? interval : 3600;

            fetch_data ();

            timeout_id = GLib.Timeout.add_seconds (interval, fetch_data);
        }

        private void stop_watcher () {
            if (timeout_id > 0) {
                GLib.Source.remove (timeout_id);
                timeout_id = 0;
            }
        }

        public override void opened () {
            fetch_data ();
        }

        public override void closed () {}
    }

}


public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    debug ("Activating Meteo Indicator");
    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION) {
        return null;
    }

    var indicator = new Meteo.Indicator ();
    return indicator;
}
