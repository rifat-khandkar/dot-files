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

#define HIDRAW_PATH1 "/dev/input/by-id/usb-CX_Wireless_mouse_-1k_dongle-hidraw"
#define HIDRAW_PATH2 "/dev/input/by-id/usb-CX_Wireless_mouse_-1k_dongle-if01-hidraw"
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

            const char *icon;
            if (battery >= 80) icon = "\xef\x89\x80";
            else if (battery >= 60) icon = "\xef\x89\x81";
            else if (battery >= 40) icon = "\xef\x89\x82";
            else if (battery >= 20) icon = "\xef\x89\x83";
            else icon = "\xef\x89\x84";

            const char *cls;
            if (battery < 30) {
                cls = "critical";
            } else {
                cls = "normal";
            }

            printf("{\"text\": \"%s %d%%\", \"class\": \"%s\"}\n",
                   icon, battery, cls);
            close(fd);
            return 0;
        }
    }

    close(fd);
    return -1;
}

int main(void) {
    if (try_device(HIDRAW_PATH2) == 0)
        return 0;
    if (try_device(HIDRAW_PATH1) == 0)
        return 0;
    return 1;
}
