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
    public class Iconame : Gtk.Image {
        public Iconame (string iconum, int size) {
            GLib.Settings settings = Meteo.Services.SettingsManager.get_default ();
            icon_size = Gtk.IconSize.DIALOG;
            icon_name = get_icon (iconum);
            if (settings.get_boolean ("symbolic")) {
                icon_name += "-symbolic";
            }
            pixel_size = size;
        }
        public static string get_icon (string code) {
            string str_icon = "";
            switch (code) {
                case "01d":
                    str_icon = "weather-clear";
                    break;
                case "01n":
                    str_icon = "weather-clear-night";
                    break;
                case "02d":
                    str_icon = "weather-few-clouds";
                    break;
                case "02n":
                    str_icon = "weather-few-clouds";
                    break;
                case "03d":
                    str_icon = "weather-few-clouds";
                    break;
                case "03n":
                    str_icon = "weather-few-clouds-night";
                    break;
                case "04d":
                    str_icon = "weather-overcast";
                    break;
                case "04n":
                    str_icon = "weather-overcast";
                    break;
                case "09d":
                    str_icon = "weather-showers-scattered";
                    break;
                case "09n":
                    str_icon = "weather-showers-scattered";
                    break;
                case "10d":
                    str_icon = "weather-showers";
                    break;
                case "10n":
                    str_icon = "weather-showers";
                    break;
                case "11d":
                    str_icon = "weather-storm";
                    break;
                case "11n":
                    str_icon = "weather-storm";
                    break;
                case "13d":
                    str_icon = "weather-snow";
                    break;
                case "13n":
                    str_icon = "weather-snow";
                    break;
                case "50d":
                    str_icon = "weather-fog";
                    break;
                case "50n":
                    str_icon = "weather-fog";
                    break;
                default :
                    str_icon = "dialog-error";
                    break;
            }
            return str_icon;
        }
    }
}
