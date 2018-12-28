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

    private const string CITY_FS = """
        .city {
            font-size: 130%;
        }
    """;

    public class Indicator : Wingpanel.Indicator {
        private Meteo.Services.Settings settings;
        private uint timeout_id;

        private Meteo.Widgets.Panel? panel_wid = null;
        private Meteo.Widgets.Popover? popover_wid = null;
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
                return this._counter;
            }
            set {
                this._counter = value;
                this.fast_check = true;
            }
        }

        public Indicator () {
            Object (code_name : "meteo-indicator",
                    display_name : "Meteo Indicator",
                    description: "Meteo Indicator displays the current weather and forecast for several days");

            settings = Meteo.Services.Settings.get_default ();
            visible = settings.get_boolean ("indicator");

            var provider = new Gtk.CssProvider ();

            try {
                provider.load_from_data (CITY_FS);
                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

                logind_manager = Bus.get_proxy_sync (BusType.SYSTEM, LOGIND_BUS_NAME, LOGIND_BUS_PATH);
                if (logind_manager != null) {
                    logind_manager.prepare_for_sleep.connect((start) => {
                        if (!start) {
                            new Thread<int>("", () => {
                                Thread.usleep(10000000);
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

            settings.changed.connect(on_settings_change);
        }

        private unowned bool update() {
            string idplace = settings.get_string ("idplace");
            if (idplace == "") {
                return false;
            }

            string lang = Gtk.get_default_language ().to_string ().substring (0, 2);
            string units = settings.get_string ("units");
            string uri_query = "?id=" + idplace + "&APPID=" + Constants.API_KEY + "&units=" + units + "&lang=" + lang;

            string uri = Constants.OWM_API_ADDR + "weather" + uri_query;
            Json.Object? today_obj = Meteo.Services.Connector.get_owh_data (uri, "current");
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

                        popover_wid.update_state (settings.get_string ("location"),
                        "%d %%".printf ((int) main_data.get_int_member ("humidity")),
                        Meteo.Utils.pressure_format ((int) main_data.get_int_member ("pressure")),
                        Meteo.Utils.wind_format (units, wind_speed, wind_deg),
                        "%d %%".printf ((int) clouds.get_int_member ("all")),
                        Meteo.Utils.time_format (new DateTime.from_unix_local (sys.get_int_member ("sunrise"))),
                        Meteo.Utils.time_format (new DateTime.from_unix_local (sys.get_int_member ("sunset"))));
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

        protected void on_settings_change(string key) {
            switch (key) {
                case "indicator":
                    if (settings.get_boolean ("indicator")) {
                        visible = true;
                        counter = 5;
                        update ();
                    } else {
                        visible = false;
                        stop_watcher ();
                    }
                    break;
                case "interval":
                    start_watcher ();
                    break;
            }

            return;
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
                popover_wid = new Meteo.Widgets.Popover ();
                update ();
            }

            return popover_wid;
        }

        public override void opened () {}
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
