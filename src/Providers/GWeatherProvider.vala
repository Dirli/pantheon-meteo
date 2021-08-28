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
            GWeather.Location gweather_location = new GWeather.Location.detached (city_name, null, latitude, longitude);
            // var gweather_location = GWeather.Location.get_world ().find_nearest_city (latitude, longitude);

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
        }

        public override void update_forecast (bool a, string units) {
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
            weather_struct.icon_name = gweather_info.get_icon_name ();
            weather_struct.description = gweather_info.get_sky ();
            weather_struct.clouds = "-";
            weather_struct.pressure = gweather_info.get_pressure ();
            weather_struct.humidity = gweather_info.get_humidity ();
            weather_struct.wind = gweather_info.get_wind ();
            weather_struct.temp = gweather_info.get_temp_summary ();

            long update_val;
            if (gweather_info.get_value_update (out update_val)) {
                weather_struct.date = update_val;
                updated_today (weather_struct);
            }
        }

        private void parse_long_forecast () {
            var forecast_array = new Gee.ArrayList<Structs.WeatherStruct?> ();

            gweather_info.get_forecast_list ().@foreach ((info_iter) => {
                long iter_date;
                if (info_iter.get_value_update (out iter_date)) {
                    Structs.WeatherStruct w_struct = {};

                    w_struct.date = iter_date;
                    w_struct.icon_name = info_iter.get_icon_name ();
                    w_struct.temp = info_iter.get_temp_summary ();

                    forecast_array.add (w_struct);
                }
            });

            updated_long (forecast_array);
        }
    }
}
