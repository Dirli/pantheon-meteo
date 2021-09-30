/*
 * Copyright (c) 2021 Dirli <litandrej85@gmail.com>
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

namespace Meteo {
    public class Providers.GWeatherProvider : Providers.AbstractProvider {
        public string city_name { get; construct set; }

        private bool advanced = false;

        private GWeather.Info gweather_info;

        public GWeatherProvider (string city, double lat, double lon) {
            Object (city_name: city,
                    latitude: lat,
                    longitude: lon);
        }

        construct {
            // GWeather.Location gweather_location = new GWeather.Location.detached (city_name, null, latitude, longitude);
            var gweather_location = GWeather.Location.get_world ();
            gweather_location = gweather_location.find_nearest_city (latitude, longitude);

            gweather_info = new GWeather.Info (gweather_location);
#if GWEATHER_40
            gweather_info.set_contact_info (Constants.CONTACTS);
#endif
            gweather_info.set_enabled_providers (GWeather.Provider.ALL);
            gweather_info.updated.connect (parse_response);
        }

        public override void get_place_id (PlaceIdDelegate cb) {
            cb ("0");
        }

        public override void update_location (Structs.LocationStruct loc) {
            latitude = loc.latitude;
            longitude = loc.longitude;
            city_name = loc.city;

            var new_location = GWeather.Location.get_world ();
            new_location = new_location.find_nearest_city (latitude, longitude);

            gweather_info.set_location (new_location);
        }

        public override void update_forecast (bool a) {
            advanced = a;

            gweather_info.update ();
        }

        private void parse_response () {
            if (!gweather_info.is_valid ()) {
                show_alert (1002);
                return;
            }

            parse_today_forecast ();
            if (advanced) {
                parse_long_forecast ();
            }
        }

        private void parse_today_forecast () {
            ulong sunrise_unix_val;
            if (gweather_info.get_value_sunrise (out sunrise_unix_val)) {
                sunrise = sunrise_unix_val;
            }

            ulong sunset_unix_val;
            if (gweather_info.get_value_sunset (out sunset_unix_val)) {
                sunset = sunset_unix_val;
            }

            Structs.WeatherStruct weather_struct = {};

            weather_struct.icon_name = use_symbolic ? gweather_info.get_symbolic_icon_name () : gweather_info.get_icon_name ();
            weather_struct.description = gweather_info.get_sky ();
            weather_struct.clouds = "-";

            var p_unit = Utils.parse_pressure_unit (units);
            double p_val;
            if (gweather_info.get_value_pressure (p_unit, out p_val)) {
                weather_struct.pressure = Utils.pressure_format (p_unit, p_val);
            }
            weather_struct.humidity = gweather_info.get_humidity ();

            var s_unit = Utils.parse_speed_unit (units);
            double w_speed;
            GWeather.WindDirection w_direction;
            if (gweather_info.get_value_wind (s_unit, out w_speed, out w_direction)) {
                weather_struct.wind = Utils.wind_format (s_unit, w_speed, w_direction - 1);
            }

            var t_unit = Utils.parse_temp_unit (units);
            double t_val;
            if (gweather_info.get_value_temp (t_unit, out t_val)) {
                weather_struct.temp = Utils.temp_format (t_unit, t_val);
            }

            long update_val;
            if (gweather_info.get_value_update (out update_val)) {
                weather_struct.date = update_val;
                updated_today (weather_struct);
            }
        }

        private void parse_long_forecast () {
            var forecast_array = new Gee.ArrayList<Structs.WeatherStruct?> ();

            var t_unit = Utils.parse_temp_unit (units);
            gweather_info.get_forecast_list ().@foreach ((info_iter) => {
                long iter_date;
                if (info_iter.get_value_update (out iter_date)) {
                    Structs.WeatherStruct w_struct = {};

                    w_struct.date = iter_date;
                    w_struct.icon_name = use_symbolic ? info_iter.get_symbolic_icon_name () : info_iter.get_icon_name ();

                    double t_val;
                    if (info_iter.get_value_temp (t_unit, out t_val)) {
                        w_struct.temp = Utils.temp_format (t_unit, t_val);
                    }

                    forecast_array.add (w_struct);
                }
            });

            updated_long (forecast_array);
        }
    }
}
