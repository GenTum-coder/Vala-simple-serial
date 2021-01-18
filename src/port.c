
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

//int fd,c, res;
//struct termios oldtio,newtio;
struct sigaction saio;           		/* объявление действия сигнала (signal action) */
char buf[255];

/*
 * 'open_port()' - Open serial port 1.
 *
 * Returns the file descriptor on success or -1 on error.
 */

int open_port()
{
	int fd; /* File descriptor for the port */

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

int is_buffer()
{
	if (wait_flag == FALSE) return 1;
	else return 0;
}

/***************************************************************************
* обработчик сигнала. устанавливает wait_flag в FALSE для индикации        *
* вышеприведенному циклу, что есть принятый символ                         *
***************************************************************************/
void signal_handler_IO (int status)
{
	printf("received SIGIO signal.\n");
	wait_flag = FALSE;
}


