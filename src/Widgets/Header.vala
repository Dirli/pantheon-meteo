namespace Meteo.Widgets {
    public class Header : Gtk.HeaderBar {

        public Gtk.Button upd_button;

        public Header (Meteo.MainWindow window, bool view) {
            show_close_button = true;

            //Create menu
            var menu = new Gtk.Menu ();
            var pref_item = new Gtk.MenuItem.with_label ("Preferences");
            menu.add (pref_item);
            pref_item.activate.connect (() => {
                var preferences = new Meteo.Widgets.Preferences (window, this);
                preferences.run ();
            });

            var app_button = new Gtk.MenuButton ();
            app_button.popup = menu;
            app_button.tooltip_text = "Options";
            app_button.image = new Gtk.Image.from_icon_name ("open-menu-symbolic", Gtk.IconSize.BUTTON);
            menu.show_all ();

            //Right buttons
            upd_button = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.BUTTON);
            upd_button.tooltip_text = "Update conditions";
            upd_button.sensitive = true;

            pack_end (app_button);
            pack_end (upd_button);

        }
    }
}
