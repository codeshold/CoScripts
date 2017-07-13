# gcc -O2 -Wall proxyd.c -o proxyd -lpthread

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <syslog.h>/* syslog定义*/
#include <sys/epoll.h>
#include <pthread.h>
#include <fcntl.h>


#define QUEUE_LEN 50


typedef 	struct pairsockets {
		int serverfd;
		int clientfd;
	} pairsockets;

pthread_mutex_t socket_mutex = PTHREAD_MUTEX_INITIALIZER;

void do_proxy(int listenfd, const char ** argv);
void *do_data_transpond(void *arg);
int create_prx2srv_con(const char **argv);
int create_listenfd(const char **argv);
int set_socket_nonblocking(int socketfd);


int main (int argc, const char **argv)
{
	int srv_listenfd = -1;

	if (4 != argc) {
		fprintf(stderr, "USAGE:%s <proxy-port> <server IP> <service-port | service-name>\r\n", argv[0]);
		exit(EXIT_FAILURE);
	}

	openlog("proxyd", LOG_CONS | LOG_PERROR | LOG_PID, 0);

	srv_listenfd = create_listenfd(argv);

	do_proxy(srv_listenfd, argv);//the main body of program

	close(srv_listenfd);
	closelog();

	return 0;
}


void do_proxy(int listenfd, const char ** argv)
{
	int epfd;
	int prx2cln_sockfd = -1;
	int prx2srv_sockfd = -1;
	int ret ;
	struct epoll_event ev, listenev;
	struct sockaddr_in client_addr;
	socklen_t client_len;
	pthread_t prx2cln_thread;
	pairsockets mysockets;

	do {
		/*1--creat a epoll instance*/
		if (-1 == (epfd = epoll_create1(0))) {
			syslog(LOG_ERR, "[%d]epoll_creat1 failed(%m)!\r\n", __LINE__);
			break;//exit from do_proxy
		}
		/*2--add event to eoll*/
		ev.events = EPOLLIN;
		ev.data.fd = listenfd;
		if (-1 == epoll_ctl(epfd, EPOLL_CTL_ADD, listenfd, &ev)) {
			syslog(LOG_ERR, "[%d]listen event epoll_ctl failed(%m)!\r\n", __LINE__);
			close(epfd);
			break;//exit from do_proxy
		}
		/*3--epoll_wait loop*/
		for(;;) {
			ret = epoll_wait(epfd, &listenev, 1, -1);
			if (-1 == ret) {
				syslog(LOG_ERR, "[%d]epoll_wait failed(%m)!\r\n", __LINE__);
				break;//exit from epoll_wait  loop
			}
			if ((listenev.events & EPOLLERR) ||(listenev.events & EPOLLHUP) || (!(listenev.events & EPOLLIN))) {
				syslog(LOG_ERR, "[%d]epoll error(%m)!\r\n", __LINE__);
				//continue;
				break;//exit from epoll_wait  loop
			}/* else if (listenfd == listenev.data.fd)*/
			//{
				while(1) {

					/*3.1 accept connections on the socket*/
					client_len = sizeof(struct sockaddr);
					prx2cln_sockfd = accept(listenfd, (struct sockaddr*)&client_addr, &client_len);
					if (-1 == prx2cln_sockfd) {
						if ((errno == EAGAIN) || (errno == EWOULDBLOCK)) {
							continue;//no new client or we have processed the connection
						}
						syslog(LOG_ERR, "[%d]accept failed(%m)\r\n", __LINE__);
						break;// back to epoll_wait loop
					}
					//syslog(LOG_ERR, "[%d] swf create socket:%d\r\n", __LINE__, prx2cln_sockfd);

					/*3.2 create a connection to service port*/
					prx2srv_sockfd = create_prx2srv_con(argv);
					if (-1 == prx2srv_sockfd) {//create failed
						syslog(LOG_ERR, "[%d]create_prx2srv_con failed!\r\n", __LINE__);
						close (prx2cln_sockfd);
						break;//back to epoll_wait loop
					}

					/*3.3 create new thread to deal with the 2 sockets*/
					pthread_mutex_lock(&socket_mutex);
					memset(&mysockets, 0, sizeof(mysockets));
					mysockets.clientfd =  prx2cln_sockfd;
					mysockets.serverfd = prx2srv_sockfd;
					//syslog(LOG_ERR, "[%d]swf clientfd:%d serverfd:%d(%m)\r\n", __LINE__, mysockets.clientfd,mysockets.serverfd);
					ret = pthread_create(&prx2cln_thread, NULL, do_data_transpond, (void *)&mysockets);
					if (0 != ret) {
						pthread_mutex_unlock(&socket_mutex);
						syslog(LOG_ERR, "create thread failed,(%d)(%s)\r\n", ret, strerror(errno));
						close(prx2cln_sockfd);
						close(prx2srv_sockfd);
						break;//back to epoll_wait loop
					}
				}
				//continue;
			//}
		}
		close(epfd);
	}while(0);

	close(listenfd);
	exit(EXIT_FAILURE);
}


void *do_data_transpond(void *arg)
{
	struct epoll_event ev, pevents[2];
	int efd;
	int done = 0;//是否完成数据转发1（完成），0（未完成）
	char buff[2048];
	int write_sockfd = -1;
	int client_sockfd = -1;
	int server_sockfd = -1;
	int i, nready;
	int exit_val = -1;
	int exit_flag = 0;//退出本线程的标志，1表示需要退出

	if (NULL == arg) {
		syslog(LOG_ERR, "[%d] args error!\r\n!", __LINE__);
		pthread_mutex_unlock(&socket_mutex);
		pthread_exit((void *)&exit_val);
	}
	client_sockfd = ((pairsockets *)arg)->clientfd;
	server_sockfd = ((pairsockets *)arg)->serverfd;
	pthread_mutex_unlock(&socket_mutex);
	//syslog(LOG_ERR, "[%d]swf client_sockfd:%d server_sockfd:%d\r\n", __LINE__, client_sockfd, server_sockfd);

	if ((0 > client_sockfd) || (0 > server_sockfd)) {
		syslog(LOG_ERR, "[%d] error--client_sockfd:%d server_sockfd:%d \r\n!", __LINE__, client_sockfd, server_sockfd);
		pthread_exit((void *)&exit_val);
	}

	do {
		/* 1.set socket nonblocking*/
		if ((-1 == set_socket_nonblocking(client_sockfd)) || (-1 == set_socket_nonblocking(server_sockfd))) {
			syslog(LOG_ERR, "[%d]set_socket_nonblocking failes!\r\n", __LINE__);
			break;
		}
		/*2.create epoll*/
		if (-1 == (efd = epoll_create1(0))) {
			syslog(LOG_ERR, "[%d]epoll_create1 failed(%m)\r\n!", __LINE__);
			break;
		}
		/*3.add events*/
		memset(&ev, 0, sizeof(ev));
		ev.data.fd = client_sockfd;
		ev.events = EPOLLIN;
		if (-1 == epoll_ctl(efd, EPOLL_CTL_ADD, client_sockfd, &ev)) {
			syslog(LOG_ERR, "[%d]epol_ctl client_sockfd failed(%m)\r\n!", __LINE__);
			close(efd);
			break;
		}
		memset(&ev, 0, sizeof(ev));
		ev.data.fd = server_sockfd;
		ev.events = EPOLLIN;
		if (-1 == epoll_ctl(efd, EPOLL_CTL_ADD, server_sockfd, &ev)) {
			syslog(LOG_ERR, "[%d]epol_ctl server_sockfd failed(%m)\r\n!", __LINE__);
			close(efd);
			break;
		}
		/*4.epoll_wait loop*/
		memset(&pevents, 0, sizeof(pevents));
		for(;;) {
		 	nready = epoll_wait(efd, pevents, 2, -1);

			for (i = 0; i < nready; i++) {
				/*deal with abnormal events*/
				if((pevents[i].events & EPOLLERR)||(pevents[i].events & EPOLLHUP) || (!(pevents[i].events & EPOLLIN))) {
					syslog(LOG_ERR, "[%d]epoll_wait!\r\n", __LINE__);
					exit_flag = 1;//exit
					break;//back to epool_wait lop
				} //else {//if(pevents[i].events & EPOLLIN)
					if ((pevents[i].data.fd != server_sockfd) && (pevents[i].data.fd != client_sockfd) ){
						continue;
					}

					done = 0;
					while(1) {
						ssize_t count = 0;
						count = read(pevents[i].data.fd, buff, sizeof(buff));
						if (-1 == count) {
							if(errno != EAGAIN) {
								done = 1;//we have read all data. So go back to the main loop
							}
							break;//back to ready events loop
						} else if(0 == count) {//End of file
							done = 1;
							break;
						} else {//transpond data
							write_sockfd = (pevents[i].data.fd == client_sockfd) ? (server_sockfd) : (client_sockfd);
							if(0 > write(write_sockfd, buff, count)) {
								syslog(LOG_ERR, "[%d]write failed(%m)\r\n!", __LINE__);
								exit_flag = 1;//exit
								break;//back to ready events loop
							}
						}
					}
					if ((1 == done) || (1 == exit_flag)) {
						exit_flag = 1;//transpond data over--should exit
						break;
					}
				//}
			}
			if (1 == exit_flag) {
				break;
			}
		 }
		close(efd);
	}while(0);

	close(client_sockfd);
	syslog (LOG_ERR, "Closed connection on descriptor %d\n", client_sockfd);
	close(server_sockfd);
	syslog (LOG_ERR, "Closed connection on descriptor %d\n", server_sockfd);
	pthread_exit((void *)&exit_val);
}

/*创建到service 端口的连接，成功返回socket Des 失败返回-1*/
int create_prx2srv_con(const char **argv)
{
	struct addrinfo hints;
	struct addrinfo *result, *rp;
	int ret;
	int srv_sockfd = -1;

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_flags = 0;
	hints.ai_protocol = 0;

	ret = getaddrinfo(argv[2], argv[3], &hints, &result);
	if (0 != ret) {
		syslog(LOG_ERR, "[%d]Please input an appropriate service port!\n\r (%s)\r\n", __LINE__, gai_strerror(ret));
		exit(EXIT_FAILURE);//exit program
	}

	for (rp = result; rp != NULL; rp = rp->ai_next) {
		/*1.create socket*/
		srv_sockfd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
		if (-1 == srv_sockfd) {
			continue;
		}
		/*2.connect on a socket*/
		if (0 == connect(srv_sockfd, rp->ai_addr, rp->ai_addrlen)) {
			//syslog(LOG_ERR, "\r\nswf[%d]srv_sockfd:%d\r\n", __LINE__, srv_sockfd);
			break;//success
		} else {
			close(srv_sockfd);
			syslog(LOG_ERR, "[%d] failed to connect --srv_sockfd:%d (%m)!\r\n", __LINE__, srv_sockfd);
			continue;
		}
	}
	freeaddrinfo(result);

	if (NULL == rp) {
		syslog(LOG_ERR, "[%d] failed to connect to server!\r\n", __LINE__);
		return -1;
	}

	//syslog(LOG_ERR, "[%d] swf create socket:%d \r\n", __LINE__,srv_sockfd);
	return srv_sockfd;
}


/*创建用于监听的socket，成功则返回socket Des，失败则exit*/
int create_listenfd(const char **argv)
{
	struct addrinfo hints;
	struct addrinfo *result, *rp;
	int ret;
	int listenfd;
	int reuseaddr_opt = 1; //for reuse port

	memset(&hints, 0, sizeof(struct addrinfo));
	hints.ai_family = AF_UNSPEC;
	hints.ai_flags = AI_PASSIVE;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = 0;
	hints.ai_canonname = NULL;
	hints.ai_addr = NULL;
	hints.ai_next = NULL;

	ret = getaddrinfo(argv[2], argv[1], &hints, &result);
	if (0 != ret) {
		syslog(LOG_ERR, "[%d] Please input an appropriate proxy port or IP address!\n\r (%s)\r\n", __LINE__, gai_strerror(ret));
		exit(EXIT_FAILURE);
	}

	for (rp = result; rp != NULL; rp = rp->ai_next) {
		/*1.create socket*/
		listenfd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
		if (-1 == listenfd) {
			syslog(LOG_ERR, "[%d] failed to create socket (%m)!\r\n", __LINE__);
			continue;
		}
		/*2.set socket reuse*/
		ret = setsockopt(listenfd, SOL_SOCKET, SO_REUSEADDR, (const void *)&reuseaddr_opt, (socklen_t)sizeof(reuseaddr_opt)) ;
		if (-1 == ret) {
			syslog(LOG_ERR, "[%d] failed to setsockopt--listenfd:%d (%m)!\r\n", __LINE__, listenfd);
			close(listenfd);
			continue;
		}
		/*3.bind a name to asocket*/
		if (-1 ==  bind(listenfd, rp->ai_addr, rp->ai_addrlen)) {
			syslog(LOG_ERR, "[%d] failed to bind--listenfd:%d (%m)!\r\n", __LINE__, listenfd);
			close(listenfd);
			continue;
		}
		/*4.listen on a socket*/
		if (0 == listen(listenfd, QUEUE_LEN)) {
			break;// success
		} else {
			syslog(LOG_ERR, "[%d] failed to listen --listenfd:%d (%m)!\r\n", __LINE__, listenfd);
			close(listenfd);
			continue;
		}
	}
	freeaddrinfo(result);

	if (NULL == rp) {
		syslog(LOG_ERR, "[%d] failed to bind socket to proxy_port(%m)!\r\n", __LINE__);
		exit(EXIT_FAILURE);
	}
	return listenfd;
}

/*设置socket为nonblocking，成功返回0，失败返回-1*/
int set_socket_nonblocking(int socketfd)
{
	int flag;

	if (0 > socketfd) {
		syslog(LOG_ERR,"[%d]:sfd invalid!\r\n", __LINE__);
		return -1;
	}

	flag = fcntl(socketfd, F_GETFL, 0);
	if (-1 == flag) {
		syslog(LOG_ERR,"[%d]:fcntl get  flag error!socketfd:%d(%m)\r\n", __LINE__, socketfd);
		return -1;
	}
	if (-1 == fcntl(socketfd, F_SETFL, flag | O_NONBLOCK)) {
		syslog(LOG_ERR, "[%d]:fcntl set nonblocking error!socketfd%d(%m)\r\n", __LINE__, socketfd);
		return -1;
	}

	return 0;
}

