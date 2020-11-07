namespace Meteo {
    public class Services.Geolocation : Services.AbstractService {
        public signal void new_location (Structs.LocationStruct location_struct);
        public signal void existing_location ();

        public string api_key {
            get; construct set;
        }

        public double latitude {
            get; set;
        }

        public double longitude {
            get; set;
        }

        public GWeather.LocationEntry? location_entry {
            get; private set;
        }

#if GEOCLUE_EXIST
        private GClue.Simple? gclue_simple;
#endif

        public Geolocation (string key) {
            Object (api_key: key);
        }

        public bool auto_detect () {
#if GEOCLUE_EXIST
            auto_detect_async.begin ();
            return true;
        }

        private async void auto_detect_async () {
            if (gclue_simple != null) {
                return;
            }

            location_entry = null;

            try {
                gclue_simple = yield new GClue.Simple ("io.elementary.meteo", GClue.AccuracyLevel.CITY, null);
                gclue_simple.notify["location"].connect (() => {
                    on_changed_location (gclue_simple.location.latitude, gclue_simple.location.longitude);
                });

                on_changed_location (gclue_simple.location.latitude, gclue_simple.location.longitude);
            } catch (Error e) {
                warning ("Failed to connect to GeoClue2 service: %s", e.message);
                show_message ("location could not be determined automatically");
            }

        }

        private void on_changed_location (double lat, double lon) {
            var location = GWeather.Location.get_world ();
            location = location.find_nearest_city (lat, lon);

            determine_id (lon, lat, location.get_city_name (), location.get_country_name ());
        }
#else
            return false;
        }
#endif


        public void manually_detect () {
            if (location_entry != null) {
                return;
            }

#if GEOCLUE_EXIST
            gclue_simple = null;
#endif
            location_entry = new GWeather.LocationEntry (GWeather.Location.get_world ());

            location_entry.placeholder_text = _("Search for new location:");
            location_entry.width_chars = 30;

            location_entry.activate.connect (location_entry_changed);
        }

        private void determine_id (double lon, double lat, string city, string country) {
            if ("%.3f".printf (lon) != "%.3f".printf (longitude) || "%.3f".printf (lat) != "%.3f".printf (latitude)) {
                string uri_query = "?lat=" + lat.to_string () + "&lon=" + lon.to_string () + "&APPID=" + api_key;
                string uri = Constants.OWM_API_ADDR + "weather" + uri_query;
                string new_idplace = Utils.update_idplace (uri).to_string ();

                latitude = lat;
                longitude = lon;

                Structs.LocationStruct loc = {};

                loc.location = city;
                loc.country = country;
                loc.idplace = new_idplace;

                new_location (loc);
            } else {
                existing_location ();
            }
        }

        private unowned void location_entry_changed () {
            location_entry.activate.disconnect (location_entry_changed);
            GWeather.Location? location = location_entry.get_location ();

            if (location != null) {
                double lon;
                double lat;
                location.get_coords (out lat, out lon);

                determine_id (lon, lat, location.get_city_name (), location.get_country_name ());
            } else {
                show_message ("location could not be determined");
            }

            location_entry = null;
        }
    }
}
