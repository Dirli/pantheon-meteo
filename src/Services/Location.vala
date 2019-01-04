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

namespace Meteo.Services {
    public class Location : GWeather.LocationEntry {
        private struct Coord {
            double lat;
            double lon;
        }
        public static void geolocate () {
            get_ip_location ((mycoord) => {
                var location = new Geocode.Location (mycoord.lat, mycoord.lon);
                var reverse = new Geocode.Reverse.for_location (location);
                try {
                    Geocode.Place mycity = reverse.resolve ();
                    if (mycity != null) {
                        new_location (mycoord, mycity.town, mycity.country);
                    }
                } catch (Error e) {
                    warning (e.message);
                }
            });
        }

        public Location () {
            new GWeather.LocationEntry(GWeather.Location.get_world());

            placeholder_text = "Search for new location:";
            width_chars = 30;

            activate.connect (location_entry_changed);
        }

        private delegate void FindPlace (Coord? mycoord);

        private static void get_ip_location (FindPlace callback) {
            var coord = Coord ();
            string uri = "https://location.services.mozilla.com/v1/geolocate?key=test";
            Soup.Session session = new Soup.Session ();
            Soup.Message message = new Soup.Message ("GET", uri);

            session.queue_message (message, (sess, mess) => {
                if (mess.status_code == 200) {
                    try {
                        var parser = new Json.Parser ();
                        parser.load_from_data ((string) mess.response_body.flatten ().data, -1);
                        var root = parser.get_root ().get_object ();
                        foreach (string name in root.get_members ()) {
                            if (name == "location") {
                                var mycoords = root.get_object_member ("location");
                                coord.lat = mycoords.get_double_member ("lat");
                                coord.lon = mycoords.get_double_member ("lng");
                                break;
                            }
                        }

                        callback (coord);
                    } catch (Error e) {
                        warning (e.message);
                    }
                } else {
                    warning ("Status Code: %u\n", mess.status_code);
                }
            });
        }


        private static void new_location (Coord coords, string city, string country) {
            string uri_query = "?lat=" + coords.lat.to_string () + "&lon=" + coords.lon.to_string () + "&APPID=" + Constants.API_KEY;
            string uri = Constants.OWM_API_ADDR + "weather" + uri_query;

            string new_idplace = Meteo.Utils.update_idplace (uri).to_string ();
            GLib.Settings settings = Meteo.Services.SettingsManager.get_default ();

            settings.set_string ("location", city);
            settings.set_double ("longitude", coords.lon);
            settings.set_double ("latitude", coords.lat);
            settings.set_string ("country", country);
            settings.set_string ("idplace", new_idplace);
        }

        private unowned void location_entry_changed() {
            GWeather.Location? location = get_location ();

            if (location != null) {
                var coord = Coord ();
                location.get_coords(out coord.lat, out coord.lon);

                new_location (coord, location.get_city_name (), location.get_country_name ());
            }
        }
    }
}
