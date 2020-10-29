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
    public class Widgets.Today : Gtk.Grid {
        public Today (Json.Object today_obj, string units, SunState sun_state) {
            Object (valign: Gtk.Align.FILL,
                    halign: Gtk.Align.CENTER,
                    row_spacing: 5,
                    column_spacing: 5,
                    margin: 15,
                    margin_start: 30,
                    vexpand: true);

            var main_data = today_obj.get_object_member ("main");

            var title = new Gtk.Label (_("Today"));
            title.get_style_context ().add_class ("weather");
            title.halign = Gtk.Align.START;

            var weather = today_obj.get_array_member ("weather");
            string wdescrip = weather.get_object_element (0).get_string_member ("description");
            Gtk.Label weather_main = new Gtk.Label (wdescrip);
            weather_main.halign = Gtk.Align.START;
            weather_main.get_style_context ().add_class ("resumen");

            string _icon = weather.get_object_element (0).get_string_member ("icon");
            var icon = new Meteo.Utils.Iconame (_icon, 128);
            icon.halign = Gtk.Align.END;
            icon.valign = Gtk.Align.START;

            double temp_n = main_data.get_double_member ("temp");
            Gtk.Label temp = new Gtk.Label (Meteo.Utils.temp_format (units, temp_n));
            temp.get_style_context ().add_class ("temp");
            temp.halign = Gtk.Align.START;
            temp.valign = Gtk.Align.CENTER;

            string pressure = Meteo.Utils.pressure_format ((int)main_data.get_int_member ("pressure"));
            Gtk.Label pres = new Gtk.Label (pressure);
            Gtk.Label pres_lb = new Gtk.Label (_("Pressure") + " :");
            pres.halign = Gtk.Align.START;
            pres_lb.halign = Gtk.Align.END;

            Gtk.Label humid = new Gtk.Label ("%d %%".printf ((int) main_data.get_int_member ("humidity")));
            Gtk.Label humid_lb = new Gtk.Label (_("Humidity") + " :");
            humid.halign = Gtk.Align.START;
            humid_lb.halign = Gtk.Align.END;

            Json.Object wind = today_obj.get_object_member ("wind");
            double? wind_speed = null;
            double? wind_deg = null;
            if (wind.has_member ("speed")) {
                wind_speed = wind.get_double_member ("speed");
            }
            if (wind.has_member ("deg")) {
                wind_deg = wind.get_double_member ("deg");
            }
            string wind_str = Meteo.Utils.wind_format (units, wind_speed, wind_deg);
            Gtk.Label wind_val = new Gtk.Label (wind_str);
            Gtk.Label wind_lb = new Gtk.Label (_("Wind") + " :");
            wind_val.halign = Gtk.Align.START;
            wind_lb.halign = Gtk.Align.END;

            var clouds = today_obj.get_object_member ("clouds");
            Gtk.Label clouds_all = new Gtk.Label ("%d %%".printf ((int) clouds.get_int_member ("all")));
            Gtk.Label clouds_lb = new Gtk.Label (_("Cloudiness") + " :");
            clouds_all.halign = Gtk.Align.START;
            clouds_lb.halign = Gtk.Align.END;

            string sunrise_t = Meteo.Utils.time_format (sun_state.sunrise);
            string sunset_t = Meteo.Utils.time_format (sun_state.sunset);
            Gtk.Label sun_r = new Gtk.Label (_("Sunrise") + " :");
            Gtk.Label sunrise = new Gtk.Label (sunrise_t);
            Gtk.Label sun_s = new Gtk.Label (_("Sunset") + " :");
            Gtk.Label sunset = new Gtk.Label (sunset_t);
            sun_s.halign = sun_r.halign = Gtk.Align.END;
            sunset.halign = sunrise.halign = Gtk.Align.START;

            attach (title,               0, 0, 4, 1);
            attach (temp,                0, 1, 1, 4);
            attach (icon,                1, 1, 1, 4);
            attach (weather_main,        0, 5, 4, 1);
            attach (wind_lb,             2, 1, 1, 1);
            attach (wind_val,            3, 1, 1, 1);
            attach (pres_lb,             2, 2, 1, 1);
            attach (pres,                3, 2, 1, 1);
            attach (humid_lb,            2, 3, 1, 1);
            attach (humid,               3, 3, 1, 1);
            attach (clouds_lb,           2, 4, 1, 1);
            attach (clouds_all,          3, 4, 1, 1);

            // attach (sun_r,               1, 8, 2, 1);
            // attach (sunrise,             3, 8, 2, 1);
            // attach (sun_s,               1, 9, 2, 1);
            // attach (sunset,              3, 9, 2, 1);
        }
    }
}
