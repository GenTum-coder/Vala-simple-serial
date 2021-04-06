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
using GLib;
using Posix;

//
extern int open_serial_port(char * device, uint32 baud_rate);
extern void close_port(int fd);
extern int is_buffer(int fd);
extern ssize_t read_port(int fd, uint8 * buffer, size_t size);
extern int write_port(int fd, uint8 * buffer, size_t size);
//

namespace ValaTerminal {
	[GtkTemplate (ui = "/org/example/vala-terminal/window.ui")]
	public class Window : Gtk.ApplicationWindow {
		[GtkChild] Label  label1;
		[GtkChild] Button button1;
		[GtkChild] Button button2;
		[GtkChild] Button button3;
		[GtkChild] Button button4;
		[GtkChild] Button button5;
		[GtkChild] Button button6;
		[GtkChild] Button button7;
		[GtkChild] Button button8;
		[GtkChild] CheckButton check1;
		[GtkChild] CheckButton check2;
		[GtkChild] CheckButton check3;
		[GtkChild] ComboBoxText combo1;
		[GtkChild] ComboBoxText combo2;
		[GtkChild] Entry  edit1;
		[GtkChild] TextView memo1;

		string str;
		int fd;
		int n;
		int t;
		int res;
		char ch;
		uint8 u8;
		uint8 buf_in[32768];
		bool  chg;

		TextBuffer buffer = new TextBuffer (null); //stores text to be displayed
		GLib.Settings settings = new GLib.Settings ("org.example.vala-terminal");

		private void send() {
			string s;
			int len;
			uint8 val;
			s = edit1.get_text();// + "\n\r";
			len = s.length;
			write_port(fd, (uint8*)s.data, (size_t)len);
			if (check2.get_active()) {
				val = 10;
				write_port(fd, &val, 1);
			}
			if (check3.get_active()) {
				val = 13;
				write_port(fd, &val, 1);
			}
		}

		private void ctrl_c() {
			uint8 val;
			val = 3;
			write_port(fd, &val, 1);
		}

		private void ctrl_d() {
			uint8 val;
			val = 4;
			write_port(fd, &val, 1);
		}

		private void ctrl_e() {
			uint8 val;
			val = 5;
			write_port(fd, &val, 1);
		}

		private void port_ctrl() {
			string sbr;
			string stty;
			if (!check1.get_active()) {
				sbr  = combo1.get_active_text();
				stty = combo2.get_active_text();
				fd = open_serial_port(stty.data, int.parse(sbr));
				if (fd != -1) {
					check1.set_active(true);
					check1.label = stty;
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

		private void tty_chg() {
			label1.label = combo2.get_active_text();
		}

		private void memo_clear() {
			str = "";
			buffer.set_text(str);
		}

		private void set_prefs() {
			settings.set_int ("combo2item", combo2.get_active());
			settings.set_int ("combo1item", combo1.get_active());
			print ("Set prefs.\n");
		}

		private void get_prefs() {
			var i = 0;
			i = settings.get_int ("combo2item");
			combo2.set_active(i);
			i = settings.get_int ("combo1item");
			combo1.set_active(i);
		}

		public Window (Gtk.Application app) {
			Object (application: app);

			str = "";
			fd  = -1;
			ch = ' ';
			chg = false;

			memo1.set_buffer(buffer);
			buffer.set_text(str);

			// set signals
			button1.clicked.connect (this.send);
			button2.clicked.connect (this.port_ctrl);
			button3.clicked.connect (this.memo_clear);
			button4.clicked.connect (this.set_prefs);
			button5.clicked.connect (this.get_prefs);
			button6.clicked.connect (this.ctrl_c);
			button7.clicked.connect (this.ctrl_d);
			button8.clicked.connect (this.ctrl_e);
			combo1.changed.connect (this.br_chg);
			combo2.changed.connect (this.tty_chg);

			GLib.TimeoutSource time_serial = new GLib.TimeoutSource(100);   // set timer in millisecond
			time_serial.set_callback(() => {
				if (fd >= 0) {
					n = is_buffer(fd);
					label1.label = "Cnt n = " + n.to_string ();
					res = (int)read_port(fd, buf_in, n);
					t = 0;
				}
				while ((fd >= 0) && (n > t)) {
					u8 = buf_in[t];
					ch = (char)u8;
					if (ch != '\r')
						str = str + ch.to_string();
					t++;
					chg = true;
				}
				if (chg)
					buffer.set_text(str);
				chg = false;

				return true;    // timer continue
				//return false;   // timer stop
			});
			time_serial.attach(null);

			// get preferenses
			combo2.set_active(settings.get_int ("combo2item"));
			combo1.set_active(settings.get_int ("combo1item"));

			// show all
			this.show_all ();
		}

		~Window() {

		}

	}

}

