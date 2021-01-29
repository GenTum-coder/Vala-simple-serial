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
//using Gee;
using Posix;

//extern functions from port.c
//extern int  open_port();
extern int open_serial_port(char * device, uint32 baud_rate);
extern void close_port(int fd);
extern int is_buffer(int fd);
extern ssize_t read_port(int fd, uint8 * buffer, size_t size);
extern int write_port(int fd, uint8 * buffer, size_t size);
//

namespace ValaTerminal {
	[GtkTemplate (ui = "/org/example/App/window.ui")]
	public class Window : Gtk.ApplicationWindow {
		[GtkChild] Label label1;
		[GtkChild] Button button1;
		[GtkChild] Button button2;
		[GtkChild] Button button3;
		[GtkChild] CheckButton check1;
		[GtkChild] ComboBoxText combo1;
		[GtkChild] ComboBoxText combo2;
		[GtkChild] Entry  edit1;
		[GtkChild] TextView memo1;

        string str;
        int fd;
        int n;
        int res;
        int t;
        char ch;
        uint8 u8;
        uint8 buf_in[32768];
        bool  chg;
        //string tty = "/dev/ttyACM0";

        TextBuffer buffer = new TextBuffer (null); //stores text to be displayed

		private void send() {
			string s;
			int len;
			s = edit1.get_text() + "\n\r";
			len = s.length;
			write_port(fd, (uint8*)s.data, (size_t)len);
		}

		private void port_ctrl() {
			string sbr;
			string stty;
			//check1.set_mode(true);
			if (!check1.get_active()) {
				sbr  = combo1.get_active_text();
				stty = combo2.get_active_text();
				//fd = open_port();
				//fd = open_serial_port(tty.data, 115200);
				//fd = open_serial_port(tty.data, int.parse(s));
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

		public Window (Gtk.Application app) {
			Object (application: app);

            str = "";
            fd  = -1;
            t = 0;
            ch = ' ';
            chg = false;

			memo1.set_buffer(buffer);
			buffer.set_text(str);

			button1.clicked.connect (this.send);
			button2.clicked.connect (this.port_ctrl);
			button3.clicked.connect (this.memo_clear);
			combo1.changed.connect (this.br_chg);
			combo2.changed.connect (this.tty_chg);


            TimeoutSource time_serial = new TimeoutSource(100);   // set timer in millisecond
            time_serial.set_callback(() => {
				//t = 0;
				if (fd >= 0) {
					n = is_buffer(fd);
					label1.label = "Cnt n = " + n.to_string ();
					res = (int)read_port(fd, buf_in, n);
					t = 0;
					//chg = true;
				}
				while ((fd >= 0) && (n > t)) {
					u8 = buf_in[t];
					ch = (char)u8;
					if (ch != '\r')
						str = str + ch.to_string();
					t++;
					chg = true;
				}
				//t = 0;
				if (chg)
                	buffer.set_text(str);
                chg = false;

                return true;    // timer continue
                //return false;   // timer stop
            });
            time_serial.attach(null);

			this.show_all ();
		}
	}
}

