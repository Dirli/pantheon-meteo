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

namespace Meteo.Utils {
    public static string parse_code (uint code) {
        switch (code) {
            case 2:
                return _("Check internet connection");
            case 400:
                return _("Data not available");
            case 426:
                return _("Problems with api-key");
            default:
                return _("Unknown problem yet");
        }
    }
    public static string get_icon_name (string code) {
        return code == "01d" ? "weather-clear" :
               code == "01n" ? "weather-clear-night" :
               code == "02d" ? "weather-few-clouds" :
               code == "02n" ? "weather-few-clouds" :
               code == "03d" ? "weather-few-clouds" :
               code == "03n" ? "weather-few-clouds-night" :
               code == "04d" ? "weather-overcast" :
               code == "04n" ? "weather-overcast" :
               code == "09d" ? "weather-showers-scattered" :
               code == "09n" ? "weather-showers-scattered" :
               code == "10d" ? "weather-showers" :
               code == "10n" ? "weather-showers" :
               code == "11d" ? "weather-storm" :
               code == "11n" ? "weather-storm" :
               code == "13d" ? "weather-snow" :
               code == "13n" ? "weather-snow" :
               code == "50d" ? "weather-fog" :
               code == "50n" ? "weather-fog" :
               "dialog-error";
    }

    public static bool save_cache (string path_json, string data) {
        try {
            var path = File.new_for_path (Environment.get_user_cache_dir () + "/" + Constants.APP_NAME);
            if (!path.query_exists ()) {
                path.make_directory ();
            }
            var fcjson = File.new_for_path (path_json);
            if (fcjson.query_exists ()) {
                fcjson.delete ();
            }
            var fcjos = new DataOutputStream (fcjson.create (FileCreateFlags.REPLACE_DESTINATION));
            fcjos.put_string (data);
        } catch (Error e) {
            warning (e.message);
            return false;
        }
        return true;
    }

    public static void clear_cache () {
        string cache_path = GLib.Environment.get_user_cache_dir () + "/" + Constants.APP_NAME;

        if (!GLib.FileUtils.test (cache_path, GLib.FileTest.IS_DIR)) {
            return;
        }

        try {
            string file_name;
            GLib.Dir dir = GLib.Dir.open (cache_path, 0);
            while ((file_name = dir.read_name ()) != null) {
                string path = GLib.Path.build_filename (cache_path, file_name);
                GLib.FileUtils.remove (path);
            }
        } catch (Error e) {
            warning (e.message);
        }
    }

    public static string temp_format (string units, double temp1, double? temp2 = null) {
        string tempformat = "%.0f".printf(temp1);
        if (temp2 != null) {
            tempformat += "...%.0f".printf(temp2);
        }
        tempformat += "\u00B0";
        switch (units) {
            case "imperial":
                tempformat += "F";
                break;
            case "metric":
            default:
                tempformat += "C";
                break;
        }
        return tempformat;
    }

    public static string time_format (GLib.DateTime datetime) {
        string timeformat = "";
        var syssetting = new Settings ("org.gnome.desktop.interface");
        if (syssetting.get_string ("clock-format") == "12h") {
            timeformat = datetime.format ("%I:%M");
        } else {
            timeformat = datetime.format ("%R");
        }

        return timeformat;
    }

    public static string wind_format (string units, double? speed = null, double? deg = null) {
        if (speed == null) {
            return "no data";
        }
        string windformat = "%.1f ".printf(speed);
        switch (units) {
            case "imperial":
                windformat += _("mph");
                break;
            case "metric":
            default:
                windformat += _("m/s");
                break;
        }

        if (deg != null) {
            double degrees = Math.floor((deg / 22.5) + 0.5);
            string[] arr = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"};
            int index = (int)(degrees % 16);

            switch (arr[index]) {
                case "N":
                case "NNE":
                case "NNW":
                    windformat += ", ↓";
                break;
                case "NE":
                    windformat += ", ↙";
                break;
                case "ENE":
                case "E":
                case "ESE":
                    windformat += ", ←";
                break;
                case "SE":
                    windformat += ", ↖";
                break;
                case "SSE":
                case "S":
                case "SSW":
                    windformat += ", ↑";
                break;
                case "SW":
                    windformat += ", ↗";
                break;
                case "WSW":
                case "W":
                case "WNW":
                    windformat += ", →";
                break;
                case "NW":
                    windformat += ", ↘";
                break;
            }
        }
        return windformat;
    }

    public static string pressure_format (int val) {
        string lang = Gtk.get_default_language ().to_string ().substring (0, 2);
        string presformat;
        switch (lang) {
            case "ru":
                double transfor_val = val * 0.750063755419211;
                presformat = "%.0f mm Hg".printf(transfor_val);
                break;
            default:
                presformat = "%d hPa".printf(val);
                break;

        }
        return presformat;
    }
}
