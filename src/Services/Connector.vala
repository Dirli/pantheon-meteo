namespace Meteo.Services {
    public class Connector : Object {
        private static DateTime now_dt;
        private static Json.Parser parser;

        public static Json.Object? get_owh_data (string url, string type) {
            GLib.Settings settings = Meteo.Services.Settings.get_default ();
            now_dt = new DateTime.now_local();
            try {
                bool save = false;
                string cache_json = Environment.get_user_cache_dir () + "/" + Constants.EXEC_NAME + @"/$type.json";
                string text = "";

                parser = new Json.Parser ();

                if ( !FileUtils.test(cache_json, FileTest.EXISTS) || check_update (type, settings)) {
                    text = get_forecast (url, type);
                    if (text != "") {
                        settings.set_int64(@"$type-update", now_dt.to_unix());
                        save = true;
                    }
                } else {
                    parser.load_from_file (cache_json);
                }
                Json.Object forecast_obj = new Json.Object ();
                forecast_obj = parser.get_root ().get_object ();

                if (save) {
                    var fcjson = File.new_for_path (cache_json);
                    if (fcjson.query_exists ()) {
                        fcjson.delete ();
                    }
                    var fcjos = new DataOutputStream (fcjson.create (FileCreateFlags.REPLACE_DESTINATION));
                    fcjos.put_string (text);
                }
                return forecast_obj;
            } catch (Error e) {
                warning (e.message);
                return null;
            }
        }

        private static bool check_update (string type, GLib.Settings settings) {
            DateTime last_update = new DateTime.from_unix_local(settings.get_int64(@"$type-update"));
            if (last_update.get_day_of_year () != now_dt.get_day_of_year ()) {
                return true;
            }
            if (type == "forecast") {
                int round_hour = ((last_update.get_hour () / 3) + 1) * 3;
                if (round_hour == 24) {
                    round_hour = 0;
                }
                if (round_hour <= now_dt.get_hour ()) {
                    return true;
                }
            } else if (type == "current") {
                if (last_update.get_hour () != now_dt.get_hour ()) {
                    return true;
                }
                if (last_update.get_minute () + 5 <= now_dt.get_minute ()) {
                    return true;
                }
            }
            return false;
        }

        private static string get_forecast (string url, string type) {
            try {
                var session = new Soup.Session ();
                var message = new Soup.Message ("GET", url);

                session.send_message (message);

                string text = (string) message.response_body.flatten ().data;
                parser.load_from_data (text, -1);
                Json.Node? node = parser.get_root ();

                if (node != null) {
                    if (type == "forecast") {
                        var cod = parser.get_root ().get_object ().get_string_member ("cod");
                        if (cod == "200") {
                            return text;
                        }
                    } else if (type == "current") {
                        var cod = parser.get_root ().get_object ().get_int_member ("cod");
                        if (cod == 200) {
                            return text;
                        }
                    }
                }
                return "";
            } catch (Error e) {
                warning (e.message);
                return "";
            }
        }
    }
}
