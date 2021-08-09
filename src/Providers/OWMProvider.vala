namespace Meteo {
    public class Providers.OWMProvider : Providers.AbstractProvider {
        public bool use_symbolic { get; construct set; }

        public string id_place {get; construct set;}
        public string api_key {get; construct set;}

        public int64 update_time = 0;

        private uint response_code;

        private Enums.ForecastType query_type = Enums.ForecastType.CURRENT;

        private GLib.DateTime now_dt = new DateTime.now_local ();

        private Json.Parser parser;

        public OWMProvider (string api, string id, bool s) {
            Object (api_key:api,
                    id_place: id,
                    use_symbolic: s);
        }

        public override Structs.WeatherStruct? get_today_forecast (string units) {
            query_type = Enums.ForecastType.CURRENT;

            var json_object = get_forecast (units);
            if (json_object == null) {
                return null;
            }

            var sys = json_object.get_object_member ("sys");
            if (sys != null) {
                sunrise = sys.get_int_member ("sunrise");
                sunset = sys.get_int_member ("sunset");
            }

            var main_data = json_object.get_object_member ("main");
            if (main_data == null) {
                return null;
            }

            Structs.WeatherStruct weather_struct = {};
            weather_struct.date = json_object.get_int_member ("dt");

            var weather_el = json_object.get_array_member ("weather").get_object_element (0);
            if (weather_el != null) {
                weather_struct.description = weather_el.get_string_member ("description");

                var icon_name = Utils.get_icon_name (weather_el.get_string_member ("icon"));
                if (use_symbolic) {
                    icon_name += "-symbolic";
                }
                weather_struct.icon_name = icon_name;
            }

            weather_struct.temp = Utils.temp_format (units, main_data.get_double_member ("temp"));
            weather_struct.pressure = Utils.pressure_format ((int) main_data.get_int_member ("pressure"));
            weather_struct.humidity = "%d %%".printf ((int) main_data.get_int_member ("humidity"));

            Json.Object wind = json_object.get_object_member ("wind");
            double? wind_speed = null;
            if (wind.has_member ("speed")) {
                wind_speed = wind.get_double_member ("speed");
            }

            double? wind_deg = null;
            if (wind.has_member ("deg")) {
                wind_deg = wind.get_double_member ("deg");
            }

            weather_struct.wind = Utils.wind_format (units, wind_speed, wind_deg);

            var clouds = json_object.get_object_member ("clouds");
            weather_struct.clouds = "%d %%".printf ((int) clouds.get_int_member ("all"));

            return weather_struct;
        }

        public override Gee.ArrayList<Structs.WeatherStruct?> get_long_forecast (string units) {
            query_type = Enums.ForecastType.PERIOD;

            var struct_array = new Gee.ArrayList<Structs.WeatherStruct?> ();

            var json_object = get_forecast (units);
            if (json_object != null) {
                Json.Array forecast_list = json_object.get_array_member ("list");
                forecast_list.foreach_element ((json_array, i, element_node) => {
                    var el_object = element_node.get_object ();
                    if (el_object != null) {
                        Structs.WeatherStruct weather_struct = {};
                        weather_struct.date = el_object.get_int_member ("dt");
                        weather_struct.temp = Utils.temp_format (units, el_object.get_object_member ("main").get_double_member ("temp"));

                        var icon_name = Utils.get_icon_name (el_object.get_array_member ("weather").get_object_element (0).get_string_member ("icon"));
                        if (use_symbolic) {
                            icon_name += "-symbolic";
                        }
                        weather_struct.icon_name = icon_name;

                        struct_array.add (weather_struct);
                    }
                });
            }

            return struct_array;
        }

        private bool update_mtime (string cache_path) {
            try {
                var cache_file = GLib.File.new_for_path (cache_path);
                if (!cache_file.query_exists ()) {
                    return false;
                }

                var info = cache_file.query_info (GLib.FileAttribute.TIME_MODIFIED, GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS, null);
                update_time = (int64) info.get_attribute_uint64 (GLib.FileAttribute.TIME_MODIFIED);
            } catch (Error e) {
                warning (e.message);
                return false;
            }

            return true;
        }

        public Json.Object? get_forecast (string units) {
            now_dt = new DateTime.now_local();
            try {
                var cache_json = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
                                                       GLib.Environment.get_user_cache_dir (),
                                                       Constants.APP_NAME,
                                                       @"$(query_type == Enums.ForecastType.CURRENT ? "current" : "forecast").json");

                parser = new Json.Parser ();



                string text = "";
                if (!update_mtime (cache_json) || need_update ()) {
                    string lang = Gtk.get_default_language ().to_string ().substring (0, 2);
                    var url_query = @"$(query_type == Enums.ForecastType.CURRENT ? "weather" : "forecast")?id=$(id_place)&APPID=$(api_key)&units=$(units)&lang=$(lang)";

                    var url = Constants.OWM_API_ADDR + url_query;
                    text = fetch_forecast (url);
                    if (text == "") {
                        return null;
                    }

                    update_time = 0;
                    Utils.save_cache (cache_json, text);
                } else {
                    parser.load_from_file (cache_json);
                }

                Json.Node? node = parser.get_root ();
                if (node != null) {
                    return node.get_object ();
                }
            } catch (Error e) {
                warning (e.message);
            }

            return null;
        }

        private bool need_update () {
            if (update_time == 0) {
                return true;
            }

            var last_update = new GLib.DateTime.from_unix_local (update_time);
            if (last_update.get_day_of_year () != now_dt.get_day_of_year ()) {
                return true;
            }

            if (query_type == Enums.ForecastType.PERIOD) {
                int round_hour = ((last_update.get_hour () / 3) + 1) * 3;
                if (round_hour <= now_dt.get_hour ()) {
                    return true;
                }
            } else if (query_type == Enums.ForecastType.CURRENT) {
                if (last_update.get_hour () != now_dt.get_hour ()) {
                    return true;
                }

                if (last_update.get_minute () + 20 <= now_dt.get_minute ()) {
                    return true;
                }
            }

            return false;
        }

        private string fetch_forecast (string url) {
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", url);

            var r_code = session.send_message (message);
            if (r_code == 200) {
                try {
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
                            if (query_type == Enums.ForecastType.PERIOD) {
                                var cod_string = forecast_object.get_string_member ("cod");
                                cod = int.parse (cod_string);
                            } else if (query_type == Enums.ForecastType.CURRENT) {
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

                // show_message (_("Couldn't parse the response"));
            } else {
                response_code = r_code;
            }

            return "";
        }
    }
}
