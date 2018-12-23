namespace Meteo.Utils {
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

    public static string wind_format (string units, double speed, double deg) {
        string windformat = "%.1f".printf(speed);
        switch (units) {
            case "imperial":
                windformat += " mph";
                break;
            case "metric":
            default:
                windformat += " m/s";
                break;
        }
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
