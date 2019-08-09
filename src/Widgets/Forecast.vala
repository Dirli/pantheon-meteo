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

namespace Meteo.Widgets {
    public class Forecast : Gtk.Grid {
        private Gtk.Box forecast_box;
        public Forecast (Json.Object forecast_obj, string units) {
            row_spacing = 5;
            column_spacing = 10;
            column_homogeneous = true;
            margin = 15;

            Gtk.ScrolledWindow scr_window = new Gtk.ScrolledWindow (null, null);

            forecast_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            scr_window.expand = true;;
            scr_window.add (forecast_box);

            Json.Array list = forecast_obj.get_array_member ("list");
            uint list_len = list.get_length ();

            if (list_len > 0) {
                forecast_by_day (list, units);
            }

            add (scr_window);
        }

        private int get_index (int periods, int day_index, int time_index) {
            int index;
            if (periods == 0) {
                index = day_index*8 + time_index;
            } else if (periods > 3) {
                if (day_index == 0) {
                    index = time_index;
                } else {
                    index = (day_index - 1) * 8 + periods + time_index;
                }
            } else {
                index = day_index * 8 + periods + time_index;
            }
            return index;
        }

        private void forecast_by_day (Json.Array list, string units) {
            DateTime now_dt = new DateTime.now_local();
            DateTime first_el_date = new DateTime.from_unix_local (list.get_object_element (0).get_int_member ("dt"));
            DateTime date;

            int first_el_hour = first_el_date.get_hour ();
            int now_hour = now_dt.get_hour ();

            if (first_el_hour < now_hour) {
                now_hour = first_el_hour;
            }

            int index, periods = (24 - now_hour) / 3;

            int days_count = (int) GLib.Math.round (list.get_length () / 8.0);
            days_count = int.min (days_count, 5);

            for (int b = 0; b < days_count; b++) {
                Gtk.Box day_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
                day_box.get_style_context ().add_class ("box");
                Gtk.Box hours_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 8);
                day_box.pack_start (hours_box);

                for (int c = 0; c < 8; c++) {
                    Gtk.Box hour_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
                    index = get_index (periods, b, c);

                    var list_element = list.get_object_element (index);
                    date = new DateTime.from_unix_local (list_element.get_int_member ("dt"));

                    if (c == 0) {
                        Gtk.Label format_time = new Gtk.Label (date.format ("%a, %d %b"));
                        day_box.pack_end (format_time);
                    }

                    Gtk.Label hour_val = new Gtk.Label (Meteo.Utils.time_format (date));
                    hour_box.add (hour_val);

                    Gtk.Image hour_icon = new Meteo.Utils.Iconame (list_element.get_array_member ("weather").get_object_element (0).get_string_member ("icon"), 36);
                    hour_box.add (hour_icon);

                    double hour_temp = list_element.get_object_member ("main").get_double_member ("temp");
                    Gtk.Label temp = new Gtk.Label (Meteo.Utils.temp_format (units, hour_temp));
                    hour_box.add (temp);

                    if (b == 0 && periods > 3 && periods == (c + 1) ) {
                        break;
                    }
                    if (b == 4 && periods < 4 && (8 - periods) == c + 1 ) {
                        break;
                    }

                    hours_box.add (hour_box);
                }

                forecast_box.add (day_box);
            }
        }
    }
}
