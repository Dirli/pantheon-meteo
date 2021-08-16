namespace Meteo {
    public class Providers.OWMProvider : Providers.AbstractProvider {
        private string units;
        public bool use_symbolic { get; construct set; }

        public string id_place {get; construct set;}
        public string api_key {get; construct set;}

        public int64 update_time = 0;

        private Json.Parser parser;

        public OWMProvider (string api, string id, bool s) {
            Object (api_key:api,
                    id_place: id,
                    use_symbolic: s);
        }

        public override void update_forecast (bool advanced, string u) {
            units = u;
            get_forecast (Enums.ForecastType.CURRENT);

            if (advanced) {
                get_forecast (Enums.ForecastType.PERIOD);
            }
        }

        private void parse_json_response (Json.Node? node, Enums.ForecastType query_type) {
            if (node != null) {
                var json_object = node.get_object ();
                if (json_object != null) {
                    if (query_type == Enums.ForecastType.CURRENT) {
                        parse_today_forecast (json_object);
                    } else {
                        parse_long_forecast (json_object);
                    }
                }
            }
        }

        private void parse_today_forecast (Json.Object json_object) {
            var sys = json_object.get_object_member ("sys");
            if (sys != null) {
                sunrise = sys.get_int_member ("sunrise");
                sunset = sys.get_int_member ("sunset");
            }

            var main_data = json_object.get_object_member ("main");
            if (main_data == null) {
                return;
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
            double? wind_deg = null;
            if (wind != null) {
                if (wind.has_member ("speed")) {
                    wind_speed = wind.get_double_member ("speed");
                }

                if (wind.has_member ("deg")) {
                    wind_deg = wind.get_double_member ("deg");
                }
            }
            weather_struct.wind = Utils.wind_format (units, wind_speed, wind_deg);

            var clouds = json_object.get_object_member ("clouds");
            if (clouds != null) {
                weather_struct.clouds = "%d %%".printf ((int) clouds.get_int_member ("all"));
            }

            updated_today (weather_struct);
        }

        private void parse_long_forecast (Json.Object json_object) {
            var struct_array = new Gee.ArrayList<Structs.WeatherStruct?> ();

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

            updated_long (struct_array);
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

        private bool need_update (Enums.ForecastType query_type) {
            if (update_time == 0) {
                return true;
            }

            var now_dt = new DateTime.now_local ();

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

        private void get_forecast (Enums.ForecastType query_type) {
            try {
                var cache_json = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S,
                                                       GLib.Environment.get_user_cache_dir (),
                                                       Constants.APP_NAME,
                                                       @"$(query_type == Enums.ForecastType.CURRENT ? "current" : "forecast").json");

                parser = new Json.Parser ();
                if (!update_mtime (cache_json) || need_update (query_type)) {
                    string lang = Gtk.get_default_language ().to_string ().substring (0, 2);
                    var url_query = @"$(query_type == Enums.ForecastType.CURRENT ? "weather" : "forecast")?id=$(id_place)&APPID=$(api_key)&units=$(units)&lang=$(lang)";

                    update_time = 0;
                    var url = Constants.OWM_API_ADDR + url_query;
                    fetch_forecast (url, query_type, cache_json);
                } else {
                    parser.load_from_file (cache_json);
                    parse_json_response (parser.get_root (), query_type);
                }
            } catch (Error e) {
                warning (e.message);
            }
        }

        private void fetch_forecast (string url, Enums.ForecastType query_type, string cache_path) {
            var session = new Soup.Session ();
            var message = new Soup.Message ("GET", url);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code != 200) {
                    //
                    return;
                }

                try {
                    string text = (string) mess.response_body.flatten ().data;
                    if (text == "") {
                        return;
                    }

                    parser.load_from_data (text, -1);
                    Utils.save_cache (cache_path, text);
                } catch (Error e) {
                    warning (e.message);
                }

                parse_json_response (parser.get_root (), query_type);
            });
        }
    }
}