namespace Meteo.Widgets {
    public class Forecast : Gtk.Grid {
        private string units;

        public Forecast (Json.Object forecast_obj) {
            valign = Gtk.Align.START;
            halign = Gtk.Align.CENTER;
            row_spacing = 5;
            column_spacing = 10;
            column_homogeneous = true;
            margin = 15;

            var settings = Meteo.Services.Settings.get_default ();
            units = settings.get_string ("units");

            Gtk.Label forecast = new Gtk.Label ("Forecast");
            forecast.get_style_context ().add_class ("weather");
            forecast.halign = Gtk.Align.START;
            attach (forecast, 0, 0, 2, 1);

            Json.Array list = forecast_obj.get_array_member ("list");
            uint list_len = list.get_length ();

            if (list_len >= 5) {
                forecast_by_hours (list);
                attach (new Gtk.Label (" "), 1, 4, 1, 1);
                if (list_len >= 25) {
                    forecast_by_day (list);
                }
            }
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

        private void forecast_by_day (Json.Array list) {
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
                double temp_min = 50;
                double temp_max = -50;
                Gtk.Image? icon = null;
                Gtk.Label time = new Gtk.Label ("-");
                for (int c = 0; c < 8; c++) {
                    index = get_index (periods, b, c);
                    var list_element = list.get_object_element (index);
                    date = new DateTime.from_unix_local (list_element.get_int_member ("dt"));
                    if (c == 0) {
                        time.label = date.format ("%a, %d %b");
                    }
                    if (date.get_hour () == 12) {
                        icon = new Meteo.Utils.Iconame (list_element.get_array_member ("weather").get_object_element (0).get_string_member ("icon"), 36);
                    }
                    double temp_n = list_element.get_object_member ("main").get_double_member ("temp");

                    if (temp_n > temp_max) {temp_max = temp_n;}
                    if (temp_n < temp_min) {temp_min = temp_n;}

                    if (b == 0 && periods > 3 && periods == (c + 1) ) {
                        break;
                    }
                    if (b == 4 && periods < 4 && (8 - periods) == c + 1 ) {
                        break;
                    }
                }

                Gtk.Label temp = new Gtk.Label (Meteo.Utils.temp_format (units, temp_min, temp_max));

                attach (time, 0, 5 + b, 2, 1);
                if (icon != null) {
                    attach (icon, 2, 5 + b, 1, 1);
                }
                attach (temp, 3, 5 + b, 2, 1);
            }
        }

        private void forecast_by_hours (Json.Array list) {
            for (int a = 0; a < 5; a++) {
                Gtk.Label time = new Gtk.Label (Meteo.Utils.time_format (new DateTime.from_unix_local (list.get_object_element (a).get_int_member ("dt"))));
                var icon = new Meteo.Utils.Iconame (list.get_object_element(a).get_array_member ("weather").get_object_element (0).get_string_member ("icon"), 36);
                double temp_n = list.get_object_element(a).get_object_member ("main").get_double_member ("temp");
                Gtk.Label temp = new Gtk.Label (Meteo.Utils.temp_format (units, temp_n));

                attach (time, a, 1, 1, 1);
                attach (icon, a, 2, 1, 1);
                attach (temp, a, 3, 1, 1);
            }
        }
    }
}
