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

//extern functions from port.c
extern int  open_port();
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
		[GtkChild] CheckButton check1;
		[GtkChild] Gtk.ComboBoxText combo1;
		[GtkChild] Entry  edit1;
		[GtkChild] TextView memo1;

        string str;
        int fd;
        int n;
        int res;
        int t;
        char ch;
        uint8 u8;
        uint8 buf_in[2048];
        uint8 buf_out[256];
        bool  chg;

        TextBuffer buffer = new TextBuffer (null); //stores text to be displayed

        private void send() {
        	string s;
        	int len;
            s = edit1.get_text() + "\n\r";
            len = s.length;
            //len = 6;
            for (int i=0;i<len;i++)
            	buf_out[i] = (uint8)s[i];
            //buf_out[0] = (uint8)'h';
            //buf_out[1] = (uint8)'e';
            //buf_out[2] = (uint8)'l';
            //buf_out[3] = (uint8)'p';
            //buf_out[4] = (uint8)'\n';
            //buf_out[5] = (uint8)'\r';
            //buf_out[6] = 0;
			write_port(fd, buf_out, (size_t)len);
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
            fd  = -1;
            t = 0;
            ch = ' ';
            chg = false;

            memo1.set_buffer(buffer);

			button1.clicked.connect (this.send);
			button2.clicked.connect (this.port_ctrl);
			combo1.changed.connect (this.br_chg);


            TimeoutSource time = new TimeoutSource(100);   // set timer in millisecond
            time.set_callback(() => {
				//t = 0;
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
				//t = 0;
				if (chg)
                	buffer.set_text(str);
                chg = false;

                return true;    // timer continue
                //return false;   // timer stop
            });
            time.attach(null);

            this.show_all ();
		}
	}
}

