namespace Meteo {
    public class Widgets.LocationEntry: Gtk.Entry {

        private GWeather.Location? location = null;
        private Gtk.ListStore list_store;
        
        construct {
            completion = new Gtk.EntryCompletion ();
            completion.set_popup_set_width (false);
            completion.set_text_column (Enums.EntryColumn.DISPLAY_NAME);
            completion.set_inline_selection (true);
            completion.match_selected.connect (on_match_selected);
            //  completion.no_matches.connect ();
            
            set_completion (completion);

            list_store =  new Gtk.ListStore (4, typeof (string), typeof (GWeather.Location), typeof (string), typeof (string));

            completion.set_match_func (match_func);
            completion.set_model (list_store);
            
            fill_locations (GWeather.Location.get_world ());
            
            //  changed.connect (on_changed);
        }

        private bool on_match_selected (Gtk.EntryCompletion c, Gtk.TreeModel model, Gtk.TreeIter iter) {
            string display_name = "";
            model.@get (iter,
                Enums.EntryColumn.DISPLAY_NAME, out display_name,
                Enums.EntryColumn.LOCATION, out location,
                -1);

            set_text (display_name);
            set_position (-1);

            return true;
        }

        public GWeather.Location get_location () {
            return location;
        }

        private void fill_locations (GWeather.Location parent_location) {
            GWeather.Location child = null;

            while ((child = parent_location.next_child (child)) != null) {
                switch (child.get_level ()) {
                    case GWeather.LocationLevel.ADM1:
                    case GWeather.LocationLevel.COUNTRY:
                    case GWeather.LocationLevel.REGION:
                        fill_locations (child);
                        break;
                    case GWeather.LocationLevel.WEATHER_STATION:
                    case GWeather.LocationLevel.CITY:
                        var display_name = @"$(child.get_name ()) $(parent_location.get_name ())";
                        var local_compare_name = child.get_sort_name ();
                        var english_compare_name = child.get_english_sort_name ();

                        Gtk.TreeIter iter;
                        list_store.insert_with_values (out iter, -1,
                            Enums.EntryColumn.DISPLAY_NAME, display_name,
                            Enums.EntryColumn.LOCATION, child,
                            Enums.EntryColumn.LOCAL_COMPARE_NAME, local_compare_name,
                            Enums.EntryColumn.ENGLISH_COMPARE_NAME, english_compare_name,
                            -1);
                        break;
                    default:
                        break;
                }
            }
        }

        public bool match_func (Gtk.EntryCompletion c, string key, Gtk.TreeIter iter) {
            string local_compare_name;
            string english_compare_name;
            list_store.get (iter, 
                            Enums.EntryColumn.LOCAL_COMPARE_NAME, out local_compare_name,
                            Enums.EntryColumn.ENGLISH_COMPARE_NAME, out english_compare_name,
                            -1);

            return match_compare_name (key.down (), local_compare_name.down ()) ||
                   match_compare_name (key.down (), english_compare_name.down ());
        }

        private bool match_compare_name (string _key, string name) {
            string key = _key.strip ();

            foreach (unowned string k in key.split (" ")) {
                if (k == "") {
                    continue;
                }

                if (!name.contains (k)) {
                    return false;
                }
            }

            return true;
        }
    }
}