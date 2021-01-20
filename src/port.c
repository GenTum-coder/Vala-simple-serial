
//#include <stdio.h>   /* Standard input/output definitions */
//#include <string.h>  /* String function definitions */
//#include <unistd.h>  /* UNIX standard function definitions */
//#include <fcntl.h>   /* File control definitions */
//#include <errno.h>   /* Error number definitions */
//#include <termios.h> /* POSIX terminal control definitions */

//#include <sys/types.h>
//#include <sys/stat.h>
//#include <fcntl.h>
//#include <termios.h>
//#include <stdio.h>

#include <termios.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/signal.h>
#include <sys/types.h>

#define FALSE 0
#define TRUE  1

// var
volatile int stop = FALSE;

void signal_handler_IO (int status);	/* объявление обработчика сигнала */
int wait_flag = TRUE;               	/* TRUE пока не получен сигнал */

int fd;  	/* File descriptor for the port */
int p1, p2, res;
//struct termios oldtio,newtio;
struct sigaction saio;           		/* объявление действия сигнала (signal action) */
char buf[32768];

/*
 * 'open_port()' - Open serial port 1.
 *
 * Returns the file descriptor on success or -1 on error.
 */

int open_port()
{
	//int fd; /* File descriptor for the port */

	fd = open("/dev/ttyUSB0", O_RDWR | O_NOCTTY | O_NDELAY);
	//fd = open( "/sysroot/dev/ttyUSB0", O_RDWR| O_NOCTTY );
	if (fd == -1)
	{
		/*
		* Could not open the port.
		*/

		perror("open_port: Unable to open /dev/ttyUSB0 - ");
	}
	else
	{
		p1  = 0;
		p2  = 0;
		res = 0;
		//fcntl(fd, F_SETFL, 0);
        /*
          устанавливаем обработчик сигнала перед установкой устройства как асинхронного
        */
        saio.sa_handler = signal_handler_IO;
        //saio.sa_mask = (__sigset_t)0;
        sigemptyset(&saio.sa_mask);
        //saio.sa_flags = 0;
        saio.sa_flags = SA_SIGINFO;
        saio.sa_restorer = NULL;
        sigaction(SIGIO, &saio, NULL);

        /*
          разрешаем процессу получать SIGIO
        */
        fcntl(fd, F_SETOWN, getpid());

        /*
          делаем файловый дескриптор асинхронным (страница руководства
          говорит, что только O_APPEND и O_NONBLOCK будут работать
          с F_SETFL...)
        */
        fcntl(fd, F_SETFL, FASYNC);

	}

	return (fd);
}

void close_port(int fd)
{
	if (fd >= 0)
		{
			close(fd);
		}
}

int set_buffer()
{
	buf[p2] = 'q';
	p2++;
	buf[p2] = 'w';
	p2++;
	buf[p2] = 0;
	return p2 - p1;
}

int is_buffer()
{
	//if (wait_flag == FALSE) return 1;
	//else return 0;
	return p2 - p1;
}

void clear_port()
{
	p1  = 0;
	p2  = 0;
	res = 0;

}

char read_char()
{
	char ch = 0;

	//res = read(fd, &buf[p2], 255);
	//buf[res+p2] = 0;
	if (p1 < p2) {
		ch = buf[p1];
		p1++;
	}
	return ch;
}

/***************************************************************************
* обработчик сигнала. устанавливает wait_flag в FALSE для индикации        *
* вышеприведенному циклу, что есть принятый символ                         *
***************************************************************************/
void signal_handler_IO (int status)
{
	//printf("received SIGIO signal.\n");
	res = read(fd, &buf[p2], 255);
	//buf[p2+res] = 0;
	p2 = p2 + res;
	buf[p2] = 0;

	wait_flag = FALSE;
}


