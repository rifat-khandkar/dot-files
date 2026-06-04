#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <poll.h>
#include <sys/ioctl.h>
#include <linux/hidraw.h>
#include <errno.h>
#include <dirent.h>

#define PAYLOAD_LEN 17
#define REPORT_ID 0x08
#define CMD_BATTERY 0x04

static uint8_t calc_checksum(uint8_t *data, int len) {
    int sum = REPORT_ID;
    for (int i = 0; i < len - 1; i++)
        sum += data[i];
    return 0x55 - (sum & 0xff);
}

static void drain_pending(int fd) {
    uint8_t tmp[64];
    struct pollfd pfd = { .fd = fd, .events = POLLIN };
    while (poll(&pfd, 1, 0) > 0) {
        if (read(fd, tmp, sizeof(tmp)) < 0)
            break;
    }
}

static int try_device(const char *path) {
    uint8_t buf[64];
    int fd, ret;

    fd = open(path, O_RDWR | O_NONBLOCK);
    if (fd < 0)
        return -1;

    drain_pending(fd);

    memset(buf, 0, PAYLOAD_LEN);
    buf[0] = REPORT_ID;
    buf[1] = CMD_BATTERY;
    buf[PAYLOAD_LEN - 1] = calc_checksum(&buf[1], PAYLOAD_LEN - 1);

    ret = write(fd, buf, PAYLOAD_LEN);
    if (ret < 0) {
        close(fd);
        return -1;
    }

    usleep(10000);

    for (int i = 0; i < 20; i++) {
        struct pollfd pfd = { .fd = fd, .events = POLLIN };
        ret = poll(&pfd, 1, 5);
        if (ret <= 0)
            break;

        memset(buf, 0, 64);
        ret = read(fd, buf, 64);
        if (ret == PAYLOAD_LEN && buf[0] == REPORT_ID && buf[1] == CMD_BATTERY) {
            int battery = buf[6];
            if (battery > 100) battery = 100;
            if (battery < 0) battery = 0;
            printf("%d\n", battery);
            close(fd);
            return 0;
        }
    }

    close(fd);
    return -1;
}

int main(void) {
    DIR *d = opendir("/dev/input/by-id/");
    if (!d) return 1;

    struct dirent *entry;
    while ((entry = readdir(d))) {
        if (strstr(entry->d_name, "VXE_R1SE")) {
            char path[256];
            snprintf(path, sizeof(path), "/dev/input/by-id/%s", entry->d_name);
            if (try_device(path) == 0) {
                closedir(d);
                return 0;
            }
        }
    }
    closedir(d);
    return 1;
}
