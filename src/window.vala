/* window.vala
 *
 * Copyright 2021 Gena
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

using Gtk;
//using Posix;

extern int  open_port();
extern void close_port(int fd);

namespace ValaTerminal {
	[GtkTemplate (ui = "/org/example/App/window.ui")]
	public class Window : Gtk.ApplicationWindow {
		[GtkChild] Label label1;
		[GtkChild] Button button1;
		[GtkChild] Button button2;
		[GtkChild] CheckButton check1;
		[GtkChild] Gtk.ComboBoxText combo1;
		[GtkChild] Entry  edit1;
		[GtkChild] TextView memo1;

        string str;
        int fd;
        TextBuffer buffer = new TextBuffer (null); //stores text to be displayed

        private void send() {
            //str = str + edit1.get_text() + "\n\r";
            str = str + edit1.get_text() + "\n";
            buffer.set_text(str);
            //buffer.insert_at_cursor(str+"\n\r", str.length);
            label1.label = combo1.get_active_text();
            //label1.label = "Hello World! + " + max.to_string ();
        }

        private void port_ctrl() {
			//check1.set_mode(true);
			if (!check1.get_active()) {
				fd = open_port();
				if (fd != -1) {
					check1.set_active(true);
					button2.label = "Disconnect";
				}
			}
			else {
				if (fd != -1) {
					close_port(fd);
					fd = -1;
				}
				check1.set_active(false);
				button2.label = "Connect";
			}

        }

        private void br_chg() {
            label1.label = combo1.get_active_text();
        }

		public Window (Gtk.Application app) {
			Object (application: app);

            str = "";

            memo1.set_buffer(buffer);

			button1.clicked.connect (this.send);
			button2.clicked.connect (this.port_ctrl);
			combo1.changed.connect (this.br_chg);

            this.show_all ();
		}
	}
}

