/*
 * Copyright (c) 2020-2021 Dirli <litandrej85@gmail.com>
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
    public class Services.Geolocation : GLib.Object {
        public signal void changed_location (Structs.LocationStruct location_struct);

#if GEOCLUE_EXIST
        private GClue.Simple? gclue_simple;
#endif

        public Geolocation () {}

        public bool auto_detect () {
#if GEOCLUE_EXIST
            auto_detect_async.begin ();
            return true;
        }

        private async void auto_detect_async () {
            if (gclue_simple != null) {
                return;
            }

            try {
                gclue_simple = yield new GClue.Simple ("io.elementary.meteo", GClue.AccuracyLevel.CITY, null);
                gclue_simple.notify["location"].connect (() => {
                    on_changed_location (gclue_simple.location.latitude, gclue_simple.location.longitude);
                });

                on_changed_location (gclue_simple.location.latitude, gclue_simple.location.longitude);
            } catch (Error e) {
                warning ("Failed to connect to GeoClue2 service: %s", e.message);
            }
        }

        private void on_changed_location (double lat, double lon) {
            var location = GWeather.Location.get_world ();
            location = location.find_nearest_city (lat, lon);

            Structs.LocationStruct loc = {};

            loc.city = location.get_city_name ();
            loc.country = location.get_country_name ();
            loc.latitude = lat;
            loc.longitude = lon;

            changed_location (loc);
        }
#else
            return false;
        }
#endif
    }
}
