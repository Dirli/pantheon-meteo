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

        public Indicator () {
            Object (code_name : "meteo-indicator");

            settings = new GLib.Settings (Constants.APP_NAME);
            visible = settings.get_boolean ("indicator");

            network_monitor = GLib.NetworkMonitor.get_default ();
            con_service = new Services.Connector ();

            settings.bind ("current-update", con_service, "current-update", GLib.SettingsBindFlags.DEFAULT);
            settings.bind ("forecast-update", con_service, "period-update", GLib.SettingsBindFlags.DEFAULT);

            try {
                var provider = new Gtk.CssProvider ();
                provider.load_from_data (CITY_FS);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                logind_manager = GLib.Bus.get_proxy_sync (GLib.BusType.SYSTEM, Constants.LOGIND_BUS_NAME, Constants.LOGIND_BUS_PATH);
                if (logind_manager != null) {
                    logind_manager.prepare_for_sleep.connect ((start) => {
                        if (!start && settings.get_boolean ("indicator")) {
                            if (network_monitor.get_connectivity () == NetworkConnectivity.FULL) {
                                start_watcher ();
                            }
                        }
                    });
                }
            } catch (Error e) {
                warning (e.message);
            }

            settings.changed["indicator"].connect (on_indicator_change);
            settings.changed["interval"].connect (on_interval_change);
        }

        public override Gtk.Widget get_display_widget () {
            if (panel_wid == null) {
                panel_wid = new Widgets.Panel ();
                if (visible) {
                    if (network_monitor.get_connectivity () == NetworkConnectivity.FULL) {
                        start_watcher ();
                    }

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
            string idplace = settings.get_string ("idplace");
            if (idplace == "" || idplace == "0" || network_monitor.get_connectivity () != NetworkConnectivity.FULL) {
                timeout_id = 0;
                return false;
            }

            string lang = Gtk.get_default_language ().to_string ().substring (0, 2);
            string units = settings.get_string ("units");

            string api_key = settings.get_string ("personal-key").replace ("/", "");
            if (api_key == "") {
                api_key = Constants.API_KEY;
            }

            string uri_query = "?id=" + idplace + "&APPID=" + api_key + "&units=" + units + "&lang=" + lang;

            Json.Object? today_obj = con_service.get_owm_data ("weather" + uri_query, Enums.ForecastType.CURRENT);
            if (today_obj != null) {
                var weather = today_obj.get_array_member ("weather");
                string icon_num = weather.get_object_element (0).get_string_member ("icon");

                var main_data = today_obj.get_object_member ("main");
                if (panel_wid != null && main_data != null) {
                    double temp_new = main_data.get_double_member ("temp");
                    panel_wid.update_state (Utils.temp_format (units, temp_new), icon_num);

                    if (popover_wid != null) {
                        var wind = today_obj.get_object_member ("wind");
                        var clouds = today_obj.get_object_member ("clouds");
                        var sys = today_obj.get_object_member ("sys");

                        double? wind_speed = null;
                        double? wind_deg = null;

                        if (wind.has_member ("speed")) {
                            wind_speed = wind.get_double_member ("speed");
                        }

                        if (wind.has_member ("deg")) {
                            wind_deg = wind.get_double_member ("deg");
                        }

                        popover_wid.update_state (
                            settings.get_string ("location"),
                            "%d %%".printf ((int) main_data.get_int_member ("humidity")),
                            Utils.pressure_format ((int) main_data.get_int_member ("pressure")),
                            Utils.wind_format (units, wind_speed, wind_deg),
                            "%d %%".printf ((int) clouds.get_int_member ("all")),
                            Utils.time_format (new DateTime.from_unix_local (sys.get_int_member ("sunrise"))),
                            Utils.time_format (new DateTime.from_unix_local (sys.get_int_member ("sunset")))
                        );
                    }
                }
            }

            return true;
        }

        protected void on_indicator_change () {
            if (settings.get_boolean ("indicator")) {
                visible = true;

                if (network_monitor.get_connectivity () == NetworkConnectivity.FULL) {
                    start_watcher ();
                }

                network_monitor.network_changed.connect (on_network_changed);
            } else {
                visible = false;
                stop_watcher ();
                network_monitor.network_changed.disconnect (on_network_changed);
            }
        }

        protected void on_interval_change () {
            start_watcher ();
        }

        private void on_network_changed (bool availabe) {
            if (network_monitor.get_connectivity () == NetworkConnectivity.FULL && timeout_id == 0) {
                start_watcher ();
            }
        }

        private void start_watcher () {
            stop_watcher ();

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
