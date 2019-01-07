namespace Meteo.Widgets {
    public class About : Granite.GtkPatch.AboutDialog {
        public About () {
            modal = true;
            destroy_with_parent = true;
            authors = {"Dirli <litandrej85@gmail.com>", "Carlos Suárez <bitseater@gmail.com>", "Paulo Galardi <lainsce@airmail.cc>"};
            comments = _("A forecast application with OpenWeatherMap API");
            license_type = Gtk.License.GPL_2_0;
            program_name = "Pantheon-meteo";
            translator_credits = "(ru) Dirli <litandrej85@gmail.com>";
            website = "https://github.com/Dirli/pantheon-meteo";
            website_label = _("website");
            logo_icon_name = "io.elementary.meteo";
            response.connect (() => {destroy ();});
            show_all ();
        }
    }
}
