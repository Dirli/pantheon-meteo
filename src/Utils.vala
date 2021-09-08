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

namespace Meteo.Utils {
    public static string parse_code (uint code) {
        switch (code) {
            case 2:
                return _("Check internet connection");
            case 400:
                return _("Data not available");
            case 426:
                return _("Problems with api-key");
            case 1000:
                return _("Couldn't fetch a forecast");
            case 1001:
                return _("Couldn't read the response");
            case 1002:
                return _("Couldn't parse the response");
            default:
                return _("Unknown problem yet");
        }
    }

    public GWeather.TemperatureUnit parse_temp_unit (int u) {
        switch (u & 3) {
            case 0:
                return GWeather.TemperatureUnit.CENTIGRADE;
            case 1:
                return GWeather.TemperatureUnit.FAHRENHEIT;
            case 2:
                // kelvin value="2"
                // centigrade value="3"
                // fahrenheit value="4"
                return (GWeather.TemperatureUnit) (((u & 00070) >> 3) + 2);
            default:
                return GWeather.TemperatureUnit.KELVIN;
        }
    }

    public GWeather.PressureUnit parse_pressure_unit (int u) {
        switch (u & 3) {
            case 0:
                return GWeather.PressureUnit.HPA;
            case 1:
                return GWeather.PressureUnit.INCH_HG;
            case 2:
                // kpa value="2"
                // hpa value="3"
                // mb value="4"
                // mm-hg value="5"
                // inch-hg value="6"

                return (GWeather.PressureUnit) (((u & 00700) >> 6) + 2);
            default:
                return GWeather.PressureUnit.HPA;
        }
    }

    public GWeather.SpeedUnit parse_speed_unit (int u) {
        switch (u & 3) {
            case 0:
                return GWeather.SpeedUnit.MS;
            case 1:
                return GWeather.SpeedUnit.MPH;
            case 2:
                // ms value="2"
                // kph value="3"
                // mph value="4"
                // knots value="5"

                return (GWeather.SpeedUnit) (((u & 07000) >> 9) + 2);
            default:
                return GWeather.SpeedUnit.MS;
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

    public static string temp_format (GWeather.TemperatureUnit t_unit, double temp1) {
        string t_label = t_unit == GWeather.TemperatureUnit.CENTIGRADE ? "\u00B0C" :
                         t_unit == GWeather.TemperatureUnit.FAHRENHEIT ? "\u00B0F" :
                         t_unit == GWeather.TemperatureUnit.KELVIN ? "K" :
                         "unknown";

        return "%.0f %s".printf (temp1, t_label);
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

    public static string wind_format (GWeather.SpeedUnit s_unit, double? speed, int wind_d) {
        if (speed == null) {
            return "no data";
        }

        string w_label = s_unit == GWeather.SpeedUnit.MS ? _("m/s") :
                         s_unit == GWeather.SpeedUnit.MPH ? _("mph") :
                         s_unit == GWeather.SpeedUnit.KPH ? _("kph") :
                         s_unit == GWeather.SpeedUnit.KNOTS ? _("knots") :
                         "unknown";

        string windformat = "%.1f %s".printf (speed, w_label);

        string[] arr = {"N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"};
        if (wind_d > -1 && wind_d < arr.length) {
            switch (arr[wind_d]) {
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

    public static string pressure_format (GWeather.PressureUnit p_unit, double p_val) {
        string p_label = p_unit == GWeather.PressureUnit.HPA ? _("hPa") :
                         p_unit == GWeather.PressureUnit.INCH_HG ? _("in Hg") :
                         p_unit == GWeather.PressureUnit.MB ? _("mb") :
                         p_unit == GWeather.PressureUnit.KPA ? _("kPa") :
                         p_unit == GWeather.PressureUnit.MM_HG ? _("mm Hg") :
                         "unknown";

        return "%.0f %s".printf (p_val, p_label);
    }
}
