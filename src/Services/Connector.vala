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
    public class Services.Connector : GLib.Object {
        public int64 current_update {get; set;}
        public int64 period_update {get; set;}

        private static Json.Parser? parser;

        private GLib.DateTime now_dt;

        public Connector () {

        }

        public Json.Object? get_owm_data (string url_query, Enums.ForecastType type) {
            now_dt = new DateTime.now_local();
            try {
                bool save = false;
                var cache_json = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
                                                       GLib.Environment.get_user_cache_dir (),
                                                       Constants.APP_NAME,
                                                       @"$(type == Enums.ForecastType.CURRENT ? "current" : "forecast").json");
                string text = "";

                parser = new Json.Parser ();

                if (!FileUtils.test(cache_json, FileTest.EXISTS) || check_update (type)) {
                    var url = Constants.OWM_API_ADDR + url_query;
                    text = get_forecast (url, type);
                    if (text == "") {
                        return null;
                    }

                    save = true;
                } else {
                    parser.load_from_file (cache_json);
                }

                Json.Object forecast_obj = new Json.Object ();
                forecast_obj = parser.get_root ().get_object ();

                if (save) {
                    if (Utils.save_cache (cache_json, text)) {
                        if (type == Enums.ForecastType.CURRENT) {
                            current_update = now_dt.to_unix ();
                        } else {
                            period_update = now_dt.to_unix ();
                        }
                    }
                }

                parser = null;
                return forecast_obj;
            } catch (Error e) {
                warning (e.message);
                return null;
            }

        }

        private bool check_update (Enums.ForecastType type) {
            var last_update = new GLib.DateTime.from_unix_local (type == Enums.ForecastType.CURRENT ? current_update : period_update);

            if (last_update.get_day_of_year () != now_dt.get_day_of_year ()) {
                return true;
            }

            if (type == Enums.ForecastType.PERIOD) {
                int round_hour = ((last_update.get_hour () / 3) + 1) * 3;
                if (round_hour <= now_dt.get_hour ()) {
                    return true;
                }

            } else if (type == Enums.ForecastType.CURRENT) {
                if (last_update.get_hour () != now_dt.get_hour ()) {
                    return true;
                }

                if (last_update.get_minute () + 20 <= now_dt.get_minute ()) {
                    return true;
                }
            }

            return false;
        }

        private string get_forecast (string url, Enums.ForecastType type) {
            try {
                var session = new Soup.Session ();
                var message = new Soup.Message ("GET", url);

                session.send_message (message);

                string text = (string) message.response_body.flatten ().data;
                parser.load_from_data (text, -1);
                Json.Node? node = parser.get_root ();

                if (node != null) {
                    var forecast_object = node.get_object ();
                    if (forecast_object == null) {
                        return "";
                    }

                    if (forecast_object.has_member ("cod")) {
                        int cod = 0;
                        if (type == Enums.ForecastType.PERIOD) {
                            var cod_string = forecast_object.get_string_member ("cod");
                            cod = int.parse (cod_string);
                        } else if (type == Enums.ForecastType.CURRENT) {
                            cod = (int) forecast_object.get_int_member ("cod");
                        }

                        if (cod == 200) {
                            return text;
                        }
                    }
                }
            } catch (Error e) {
                warning (e.message);
            }

            return "";
        }
    }
}
