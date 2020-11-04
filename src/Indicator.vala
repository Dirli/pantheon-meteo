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


        private bool fast_check = true;
        private uint _counter = 5;
        private uint counter {
            get {
                if (_counter > 0) {
                    _counter -= 1;
                } else {
                    fast_check = false;
                }
                return _counter;
            }
            set {
                _counter = value;
                fast_check = true;
            }
        }

        public Indicator () {
            Object (code_name : "meteo-indicator");

            settings = Meteo.Services.SettingsManager.get_default ();
            visible = settings.get_boolean ("indicator");

            var provider = new Gtk.CssProvider ();

            try {
                provider.load_from_data (CITY_FS);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                logind_manager = GLib.Bus.get_proxy_sync (GLib.BusType.SYSTEM,
                                                          Constants.LOGIND_BUS_NAME,
                                                          Constants.LOGIND_BUS_PATH);
                if (logind_manager != null) {
                    logind_manager.prepare_for_sleep.connect((start) => {
                        if (!start) {
                            new GLib.Thread<int> ("", () => {
                                GLib.Thread.usleep (10000000);
                                counter = 5;
                                update ();
                                return 0;
                            });
                        }
                    });
                }
            } catch (Error e) {
                warning (e.message);
            }

            settings.changed["indicator"].connect (on_indicator_change);
            settings.changed["interval"].connect (on_interval_change);
        }

        private unowned bool update() {
            string idplace = settings.get_string ("idplace");
            if (idplace == "" || idplace == "0") {
                return false;
            }

            string lang = Gtk.get_default_language ().to_string ().substring (0, 2);
            string units = settings.get_string ("units");

            string api_key = settings.get_string ("personal-key").replace ("/", "");
            if (api_key == "") {
                api_key = Constants.API_KEY;
            }

            string uri_query = "?id=" + idplace + "&APPID=" + api_key + "&units=" + units + "&lang=" + lang;

            Json.Object? today_obj = Meteo.Services.Connector.get_owm_data ("weather" + uri_query, "current");
            if (today_obj != null) {
                if (fast_check) {
                    fast_check = false;
                    start_watcher ();
                }
                var weather = today_obj.get_array_member ("weather");
                string icon_num = weather.get_object_element (0).get_string_member ("icon");

                var main_data = today_obj.get_object_member ("main");
                double temp_new = main_data.get_double_member ("temp");
                if (panel_wid != null) {
                    panel_wid.update_state (Meteo.Utils.temp_format (units, temp_new), icon_num);

                    if (popover_wid != null) {
                        var wind = today_obj.get_object_member ("wind");
                        double? wind_speed = null;
                        double? wind_deg = null;

                        if (wind.has_member ("speed")) {
                            wind_speed = wind.get_double_member ("speed");
                        }

                        if (wind.has_member ("deg")) {
                            wind_deg = wind.get_double_member ("deg");
                        }

                        var clouds = today_obj.get_object_member ("clouds");
                        var sys = today_obj.get_object_member ("sys");

                        popover_wid.update_state (
                            settings.get_string ("location"),
                            "%d %%".printf ((int) main_data.get_int_member ("humidity")),
                            Meteo.Utils.pressure_format ((int) main_data.get_int_member ("pressure")),
                            Meteo.Utils.wind_format (units, wind_speed, wind_deg),
                            "%d %%".printf ((int) clouds.get_int_member ("all")),
                            Meteo.Utils.time_format (new DateTime.from_unix_local (sys.get_int_member ("sunrise"))),
                            Meteo.Utils.time_format (new DateTime.from_unix_local (sys.get_int_member ("sunset")))
                        );
                    }
                }
            } else if (fast_check) {
                uint counter_val = counter;
                if (counter_val == 0 || counter_val == 4) {
                    start_watcher ();
                }
            }

            return true;
        }

        protected void on_indicator_change () {
            if (settings.get_boolean ("indicator")) {
                visible = true;
                counter = 5;
                update ();
            } else {
                visible = false;
                stop_watcher ();
            }
        }

        protected void on_interval_change () {
            start_watcher ();
        }

        public override Gtk.Widget get_display_widget () {
            if (panel_wid == null) {
                panel_wid = new Meteo.Widgets.Panel ();
                if (visible) {
                    update ();
                }
            }

            return panel_wid;
        }

        private void start_watcher () {
            if (timeout_id > 0) {
                Source.remove (timeout_id);
            }

            uint interval;
            if (this.fast_check) {
                interval = 20;
            } else {
                interval = settings.get_int ("interval") * 3600;
                interval = interval >= 3600 ? interval : 3600;
            }

            timeout_id = GLib.Timeout.add_seconds (interval, update);
        }

        private void stop_watcher () {
            if (timeout_id > 0) {
                Source.remove (timeout_id);
            }
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

        public override void opened () {
            update ();
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
