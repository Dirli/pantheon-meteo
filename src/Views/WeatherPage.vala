namespace Meteo {
    public class Views.WeatherPage : Gtk.Box {
        private bool sunrise_added = false;
        private bool sunset_added = false;

        private GLib.DateTime sunrise_time;
        private GLib.DateTime sunset_time;

        private Gtk.Image today_icon;
        private Gtk.Label today_temp;
        private Gtk.Label today_pressure;
        private Gtk.Label today_humidity;
        private Gtk.Label today_wind;
        private Gtk.Label today_clouds;
        private Gtk.Label weather_main;

        private Gtk.Stack forecast_stack;

        public WeatherPage () {
            Object (orientation: Gtk.Orientation.VERTICAL,
                    margin: 30,
                    spacing: 20);
        }

        construct {
            // today
            var today_grid = new Gtk.Grid ();
            today_grid.valign = Gtk.Align.CENTER;
            today_grid.halign = Gtk.Align.CENTER;
            today_grid.row_spacing = 5;
            today_grid.column_spacing = 5;
            today_grid.vexpand = true;

            var today_title = new Gtk.Label (_("Today"));
            today_title.halign = Gtk.Align.START;
            today_title.get_style_context ().add_class ("weather");

            today_icon = new Gtk.Image ();
            today_icon.pixel_size = 128;
            today_icon.halign = Gtk.Align.END;
            today_icon.valign = Gtk.Align.START;

            today_temp = new Gtk.Label (null);
            today_temp.halign = Gtk.Align.START;
            today_temp.valign = Gtk.Align.CENTER;
            today_temp.get_style_context ().add_class ("temp");

            weather_main = new Gtk.Label (null);
            weather_main.halign = Gtk.Align.START;
            weather_main.get_style_context ().add_class ("resumen");

            today_pressure = new Gtk.Label (null);
            today_pressure.halign = Gtk.Align.START;
            var today_pressure_label = new Gtk.Label (_("Pressure:"));
            today_pressure_label.halign = Gtk.Align.END;

            today_humidity = new Gtk.Label (null);
            today_humidity.halign = Gtk.Align.START;
            var today_humidity_label = new Gtk.Label (_("Humidity:"));
            today_humidity_label.halign = Gtk.Align.END;

            today_wind = new Gtk.Label (null);
            today_wind.halign = Gtk.Align.START;
            Gtk.Label today_wind_label = new Gtk.Label (_("Wind:"));
            today_wind_label.halign = Gtk.Align.END;

            today_clouds = new Gtk.Label (null);
            today_clouds.halign = Gtk.Align.START;
            Gtk.Label today_clouds_label = new Gtk.Label (_("Cloudiness:"));
            today_clouds_label.halign = Gtk.Align.END;

            today_grid.attach (today_title,          0, 0, 4, 1);
            today_grid.attach (today_temp,           0, 1, 1, 4);
            today_grid.attach (today_icon,           1, 1, 1, 4);
            today_grid.attach (weather_main,         0, 5, 4, 1);
            today_grid.attach (today_wind_label,     2, 1, 1, 1);
            today_grid.attach (today_wind,           3, 1, 1, 1);
            today_grid.attach (today_pressure_label, 2, 2, 1, 1);
            today_grid.attach (today_pressure,       3, 2, 1, 1);
            today_grid.attach (today_humidity_label, 2, 3, 1, 1);
            today_grid.attach (today_humidity,       3, 3, 1, 1);
            today_grid.attach (today_clouds_label,   2, 4, 1, 1);
            today_grid.attach (today_clouds,         3, 4, 1, 1);

            // forecast
            forecast_stack = new Gtk.Stack ();

            var stack_switcher = new Gtk.StackSwitcher ();
            stack_switcher.homogeneous = true;
            stack_switcher.stack = forecast_stack;

            var forecast_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24);
            forecast_box.halign = Gtk.Align.CENTER;
            forecast_box.valign = Gtk.Align.END;
            forecast_box.add (forecast_stack);
            forecast_box.add (stack_switcher);

            var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            separator.valign = Gtk.Align.END;

            add (today_grid);
            add (separator);
            add (forecast_box);
        }

        public void set_sun_state (int64 sunrise_unix, int64 sunset_unix) {
            sunrise_time = new GLib.DateTime.from_unix_local (sunrise_unix);
            sunset_time = new GLib.DateTime.from_unix_local (sunset_unix);
        }

        public void reset_today () {
            sunrise_added = false;
            sunset_added = false;
        }

        public void clear_forecast () {
            foreach (unowned Gtk.Widget box in forecast_stack.get_children ()) {
                forecast_stack.remove (box);
            }
        }

        public void update_today (Structs.WeatherStruct weather_struct) {
            today_icon.set_from_icon_name (weather_struct.icon_name, Gtk.IconSize.DIALOG);

            today_temp.label = weather_struct.temp;
            today_pressure.label = weather_struct.pressure;
            today_humidity.label = weather_struct.humidity;
            today_wind.label = weather_struct.wind;
            today_clouds.label = weather_struct.clouds;
            weather_main.label = weather_struct.description;
        }

        public void add_day_label (GLib.DateTime date, int day_index) {
            var forecast_day = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
            forecast_day.halign = Gtk.Align.CENTER;
            forecast_stack.add_titled (forecast_day, @"$day_index", date.format ("%a, %d %b"));
        }

        public bool add_forecast_time (int day_index, GLib.DateTime forecast_time, string icon_name, string forecast_temp) {
            var forecast_day = forecast_stack.get_child_by_name (@"$day_index");
            if (forecast_day == null) {
                return false;
            }

            if (!sunrise_added && sunrise_time.get_day_of_year () == forecast_time.get_day_of_year ()) {
                if (forecast_time.get_hour () > sunrise_time.get_hour () && (forecast_time.get_hour () - 3) <= sunrise_time.get_hour ()) {
                    sunrise_added = true;

                    Gtk.Box sunrise_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
                    sunrise_box.add (new Gtk.Label (Utils.time_format (sunrise_time)));
                    sunrise_box.add (new Gtk.Image.from_icon_name ("daytime-sunrise-symbolic", Gtk.IconSize.DIALOG));

                    ((Gtk.Box) forecast_day).add (sunrise_box);
                }
            }

            if (!sunset_added && sunset_time.get_day_of_year () == forecast_time.get_day_of_year ()) {
                if (forecast_time.get_hour () > sunset_time.get_hour () && (forecast_time.get_hour () - 3) <= sunset_time.get_hour ()) {
                    sunset_added = true;

                    Gtk.Box sunset_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
                    sunset_box.add (new Gtk.Label (Utils.time_format (sunset_time)));
                    sunset_box.add (new Gtk.Image.from_icon_name ("daytime-sunset-symbolic", Gtk.IconSize.DIALOG));

                    ((Gtk.Box) forecast_day).add (sunset_box);
                }
            }

            var forecast_icon = new Gtk.Image.from_icon_name (icon_name, Gtk.IconSize.DIALOG);
            forecast_icon.pixel_size = 36;

            Gtk.Box hour_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            hour_box.add (new Gtk.Label (Utils.time_format (forecast_time)));
            hour_box.add (forecast_icon);
            hour_box.add (new Gtk.Label (forecast_temp));

            ((Gtk.Box) forecast_day).add (hour_box);

            return true;
        }
    }
}
